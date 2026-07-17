"""
model_utils.py (adapted)

Changes from original:
- Replaced tensorflow_addons.WeightNormalization with a native TF2.13 implementation.
  tensorflow-addons was discontinued and dropped support for TF >= 2.13.
- No functional changes to the TCN architecture itself.
"""
import tensorflow as tf


class WeightNormalization(tf.keras.layers.Wrapper):
    """
    Native re-implementation of WeightNormalization without tensorflow-addons.
    This wraps a Conv1D layer and normalizes its kernel using weight normalization.
    """

    def __init__(self, layer, data_init=True, **kwargs):
        super().__init__(layer, **kwargs)
        self.data_init = data_init
        self._initialized = False

    def build(self, input_shape):
        self.layer.build(input_shape)
        kernel = self.layer.kernel
        self.kernel_norm_axes = list(range(kernel.shape.rank - 1))

        self.v = self.layer.kernel
        self.g = self.add_weight(
            name="g",
            shape=(kernel.shape[-1],),
            initializer="ones",
            dtype=kernel.dtype,
            trainable=True,
        )
        self.built = True

    def call(self, inputs, training=None):
        kernel = self.v
        kernel_norm = tf.sqrt(
            tf.reduce_sum(tf.square(kernel), axis=self.kernel_norm_axes, keepdims=True)
        )
        self.layer.kernel = self.g * kernel / (kernel_norm + 1e-8)
        outputs = self.layer(inputs)
        self.layer.kernel = self.v
        return outputs

    def get_config(self):
        config = super().get_config()
        config.update({"data_init": self.data_init})
        return config


class BasicTCNBlock(tf.keras.Model):
    def __init__(self, block_num, filter_num, kernel_size, dilation_rate, window_size, use_bias, kernel_initializer,
                 dropout_rate, dropout_format, activation, final_activation):
        super(BasicTCNBlock, self).__init__()

        self.dropout_rate = dropout_rate
        valid_dropout_formats = {"channel", "timestep", "all"}
        if dropout_format not in valid_dropout_formats:
            raise ValueError("Dropout format must be one of %r." % valid_dropout_formats)
        if dropout_format == "channel":
            self.noise_shape = [1, filter_num]
        elif dropout_format == "timestep":
            self.noise_shape = [window_size, 1]
        else:
            self.noise_shape = [window_size, filter_num]

        self.tcn_1 = tf.keras.layers.Conv1D(filters=filter_num, kernel_size=kernel_size, padding="causal",
                                            dilation_rate=dilation_rate, use_bias=use_bias,
                                            kernel_initializer=kernel_initializer, name=f"{block_num}_tcn_1")
        self.weight_norm_layer_1 = WeightNormalization(self.tcn_1, data_init=False, name=f"{block_num}_wn_1")

        self.tcn_2 = tf.keras.layers.Conv1D(filters=filter_num, kernel_size=kernel_size, padding="causal",
                                            dilation_rate=dilation_rate, use_bias=use_bias,
                                            kernel_initializer=kernel_initializer, name=f"{block_num}_tcn_2")
        self.weight_norm_layer_2 = WeightNormalization(self.tcn_2, data_init=False, name=f"{block_num}_wn_2")

        self.tcn_3 = tf.keras.layers.Conv1D(filters=filter_num, kernel_size=1, padding="causal",
                                            dilation_rate=dilation_rate, use_bias=use_bias,
                                            kernel_initializer=kernel_initializer, name=f"{block_num}_tcn_3")
        self.weight_norm_layer_3 = WeightNormalization(self.tcn_3, data_init=False, name=f"{block_num}_wn_3")

        self.dropout_layer_1 = tf.keras.layers.Dropout(rate=self.dropout_rate, noise_shape=self.noise_shape,
                                                       name=f"{block_num}_dropout_1")
        self.dropout_layer_2 = tf.keras.layers.Dropout(rate=self.dropout_rate, noise_shape=self.noise_shape,
                                                       name=f"{block_num}_dropout_2")

        self.activation = tf.keras.layers.Activation(activation)
        self.final_activation = tf.keras.layers.Activation(final_activation)

    def call(self, input_tensor):
        x = self.weight_norm_layer_1(input_tensor)
        x = self.activation(x)
        x = self.dropout_layer_1(x)
        x = self.weight_norm_layer_2(x)
        x = self.activation(x)
        x = self.dropout_layer_2(x)
        res = self.weight_norm_layer_3(input_tensor)
        x = tf.math.add(res, x)
        x = self.final_activation(x)
        return x


class TCNStack(tf.keras.Model):
    def __init__(self, layer_num, filter_num, kernel_size, window_size,
                 use_bias, kernel_initializer, dropout_rate, dropout_format, activation, final_activation,
                 final_stack_activation):
        super(TCNStack, self).__init__()
        self.kernel_size = kernel_size
        self.filter_num = filter_num
        self.use_bias = use_bias
        self.window_size = window_size
        self.layer_num = layer_num
        self.kernel_initializer = kernel_initializer
        self.dropout_rate = dropout_rate
        self.dropout_format = dropout_format
        self.activation = activation
        self.final_activation = final_activation
        self.final_stack_activation = final_stack_activation

        self.block_seq = tf.keras.models.Sequential()

    def build(self, input_shape):
        for i in range(self.layer_num - 1):
            self.block_seq.add(
                BasicTCNBlock(i, self.filter_num, self.kernel_size, 2 ** i, self.window_size,
                              self.use_bias, self.kernel_initializer, self.dropout_rate, self.dropout_format,
                              self.activation, self.final_activation))
        self.block_seq.add(
            BasicTCNBlock(self.layer_num - 1, self.filter_num, self.kernel_size, 2 ** (self.layer_num - 1),
                          self.window_size,
                          self.use_bias, self.kernel_initializer, self.dropout_rate, self.dropout_format,
                          self.activation, self.final_stack_activation))

    def call(self, input_tensor):
        x = self.block_seq(input_tensor)
        return x


class TCN(tf.keras.Model):

    def get_config(self):
        pass

    def __init__(self, tcn_layer_num, tcn_kernel_size, tcn_filter_num, window_size, forecast_horizon, use_bias,
                 kernel_initializer, tcn_dropout_rate, tcn_dropout_format, tcn_activation, tcn_final_activation,
                 tcn_final_stack_activation):
        super(TCN, self).__init__()

        self.lower_tcn = TCNStack(tcn_layer_num, tcn_filter_num, tcn_kernel_size, window_size, use_bias,
                                  kernel_initializer, tcn_dropout_rate, tcn_dropout_format, tcn_activation,
                                  tcn_final_activation, tcn_final_stack_activation)

        self.out_seq = tf.keras.models.Sequential()
        self.out_seq.add(tf.keras.layers.Flatten())
        self.out_seq.add(tf.keras.layers.Dense(forecast_horizon, activation=None))

    def call(self, input_tensor):
        x = self.lower_tcn(input_tensor)
        out = self.out_seq(x)
        return out

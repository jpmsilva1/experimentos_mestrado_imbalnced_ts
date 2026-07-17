import tensorflow as tf
from tensorflow_addons.layers import WeightNormalization


class BasicTCNBlock(tf.keras.Model):
    def __init__(self, block_num, filter_num, kernel_size, dilation_rate, window_size, use_bias, kernel_initializer,
                 dropout_rate,
                 dropout_format, activation, final_activation):
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
                                            kernel_initializer=kernel_initializer, name=F"{block_num}_tcn_1")
        self.weight_norm_layer_1 = WeightNormalization(self.tcn_1, data_init=False, name=F"{block_num}_wn_1")

        self.tcn_2 = tf.keras.layers.Conv1D(filters=filter_num, kernel_size=kernel_size, padding="causal",
                                            dilation_rate=dilation_rate, use_bias=use_bias,
                                            kernel_initializer=kernel_initializer, name=F"{block_num}_tcn_2")
        self.weight_norm_layer_2 = WeightNormalization(self.tcn_2, data_init=False, name=F"{block_num}_wn_2")

        self.tcn_3 = tf.keras.layers.Conv1D(filters=filter_num, kernel_size=1, padding="causal",
                                            dilation_rate=dilation_rate, use_bias=use_bias,
                                            kernel_initializer=kernel_initializer, name=F"{block_num}_tcn_3")
        self.weight_norm_layer_3 = WeightNormalization(self.tcn_3, data_init=False, name=F"{block_num}_wn_3")

        self.dropout_layer_1 = tf.keras.layers.Dropout(rate=self.dropout_rate, noise_shape=self.noise_shape,
                                                       name=F"{block_num}_dropout_1")

        self.dropout_layer_2 = tf.keras.layers.Dropout(rate=self.dropout_rate, noise_shape=self.noise_shape,
                                                       name=F"{block_num}_dropout_2")

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
                 use_bias,
                 kernel_initializer, dropout_rate, dropout_format, activation, final_activation,
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

        # Create stack of TCN layers
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

        # Create stack of TCN layers
        self.lower_tcn = TCNStack(tcn_layer_num, tcn_filter_num, tcn_kernel_size, window_size, use_bias,
                                  kernel_initializer, tcn_dropout_rate, tcn_dropout_format, tcn_activation,
                                  tcn_final_activation, tcn_final_stack_activation)

        # Create stack of dense layers
        self.out_seq = tf.keras.models.Sequential()
        self.out_seq.add(tf.keras.layers.Flatten())
        self.out_seq.add(tf.keras.layers.Dense(forecast_horizon, activation=None))

    def call(self, input_tensor):
        x = self.lower_tcn(input_tensor)
        out = self.out_seq(x)
        return out

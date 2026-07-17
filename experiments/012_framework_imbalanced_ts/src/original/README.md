Publicly available code for the experiments conducted as described in [A Framework for Imbalanced Time-series Forecasting](https://arxiv.org/abs/2107.10709)  using the public dataset obtained from a mining process.

The data can be downloaded [here](https://www.kaggle.com/edumagalhaes/quality-prediction-in-a-mining-process).

The table below shows the results from the step 3 of our framework. The weight function was simply the regression target ($`w_i = y_i`$).
The result in bold is the mimimum test error across all test sets for the specific model.


| Model | Trained on | Tested on |||| Max Error |
| -- | ----------- | -------- | -- | -- | -- | -- |
|      |                | All data       | SUS 1 | SUS 3 | IHS |            |
| LSTM | All data                 | 0.620 +- 0.016 | 0.528 +- 0.048           | 0.675 +- 0.052           | 0.547 +- 0.048     | 0.675 +- 0.052 |
|      | SUS 1 | 0.594 +- 0.031 | 0.634 +- 0.016           | 0.600 +- 0.039           | 0.563 +- 0.036     | **0.634 +- 0.016** |
|      | SUS 3 | 0.731 +- 0.028 | 0.621 +- 0.022           | 0.633 +- 0.012           | 0.609 +- 0.031     | 0.731 +- 0.028 |
|      | IHS       | 0.638 +- 0.032 | 0.587 +- 0.031           | 0.571 +- 0.045           | 0.643 +- 0.018     | 0.643 +- 0.018 |
| TCN  | All data                 | 0.570 +- 0.009 | 0.533 +- 0.023           | 0.705 +- 0.031           | 0.578 +- 0.027     | 0.705 +- 0.031 |
|      | SUS 1 | 0.603 +- 0.015 | 0.586 +- 0.010           | 0.644 +- 0.026           | 0.606 +- 0.023     | 0.644 +- 0.026 |
|      | SUS 3 | 0.690 +- 0.022 | 0.580 +- 0.015           | 0.592 +- 0.009           | 0.561 +- 0.020     | 0.690 +- 0.022 |
|      | IHS       | 0.617 +- 0.018 | 0.538 +- 0.019           | 0.566 +- 0.021           | 0.599 +- 0.013     | **0.617 +- 0.018** |

If you find this work helpful in your research, consider citing our paper:


```
@article{silvestrin2021framework,
title={A Framework for Imbalanced Time-series Forecasting},
author={Silvestrin, Luis P and Pantiskas, Leonardos and Hoogendoorn, Mark},
journal={arXiv preprint arXiv:2107.10709},
year={2021}
}
```

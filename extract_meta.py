import pypdf
import sys

pdfs = [
    "/Users/joaopms/Library/CloudStorage/GoogleDrive-jpms5@cin.ufpe.br/My Drive/Papers Mestrado - João/A cost-sensitive active learning algorithm.pdf",
    "/Users/joaopms/Library/CloudStorage/GoogleDrive-jpms5@cin.ufpe.br/My Drive/Papers Mestrado - João/Papers Times Series/A_deep-learning_prediction_model_for_imbalanced_time_series_data_forecasting.pdf",
    "/Users/joaopms/Library/CloudStorage/GoogleDrive-jpms5@cin.ufpe.br/My Drive/Papers Mestrado - João/Papers Times Series/Improving_the_Forecasting_and_Classification_of_Extreme_Events_in_Imbalanced_Time_Series_Through_Block_Resampling_in_the_Joint_Predictor-Forecast_Space.pdf",
    "/Users/joaopms/Library/CloudStorage/GoogleDrive-jpms5@cin.ufpe.br/My Drive/Papers Mestrado - João/Demais Artigos/Resampling strategies for imbalanced regression.pdf",
    "/Users/joaopms/Library/CloudStorage/GoogleDrive-jpms5@cin.ufpe.br/My Drive/Papers Mestrado - João/Demais Artigos/Biased Resampling Strategies for Imbalanced.pdf",
    "/Users/joaopms/Library/CloudStorage/GoogleDrive-jpms5@cin.ufpe.br/My Drive/Papers Mestrado - João/Demais Artigos/s10994-025-06991-y.pdf"
]

for pdf in pdfs:
    print(f"\n--- {pdf.split('/')[-1]} ---")
    try:
        reader = pypdf.PdfReader(pdf)
        meta = reader.metadata
        print("Metadata:", meta)
        text = reader.pages[0].extract_text()
        print("First page text snippet:", text[:1000].replace('\n', ' '))
    except Exception as e:
        print("Error:", e)


import os
import json
import pickle
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score, confusion_matrix

def _generate_synthetic_data(n_samples: int = 1800):
    """
    Generate synthetic training data representing high-precision acoustic signatures.
    Features: [mfcc_1..20, pitch_hz, rms_energy, spectral_centroid, zcr, rolloff, chroma_1..12] (37 features)
    Labels: 0=Tamasic, 1=Rajasic, 2=Sattvic
    """
    np.random.seed(42)
    X, y = [], []

    for guna_idx in range(3):
        for _ in range(n_samples // 3):
            if guna_idx == 0:  # Tamasic — low energy, low pitch, heavy
                mfcc_means = [-330.0, 5.0, 2.0, 1.0, 0.0, -1.0, -2.0, -1.0, 0.0, 1.0, 0.0, -1.0, 0.0] + [0.0]*7
                mfccs = np.random.normal(mfcc_means, 8.0, 20)
                pitch = np.random.normal(115, 25)
                energy = np.random.normal(0.8, 0.3)
                centroid = np.random.normal(10.0, 2.0)
                zcr = np.random.normal(4.0, 1.5)
                rolloff = np.random.normal(10.0, 2.0)
                chroma = np.random.normal(0.4, 0.1, 12)
            elif guna_idx == 1:  # Rajasic — high energy, high pitch, fast
                mfcc_means = [-270.0, 8.0, 5.0, 4.0, 3.0, 2.0, 2.0, 1.0, 1.0, 0.0, 0.0, 1.0, 0.0] + [0.0]*7
                mfccs = np.random.normal(mfcc_means, 8.0, 20)
                pitch = np.random.normal(175, 35)
                energy = np.random.normal(3.2, 0.8)
                centroid = np.random.normal(22.0, 4.0)
                zcr = np.random.normal(11.0, 3.0)
                rolloff = np.random.normal(25.0, 5.0)
                chroma = np.random.normal(0.6, 0.15, 12)
            else:  # Sattvic — moderate, balanced
                mfcc_means = [-300.0, 6.0, 3.0, 2.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0] + [0.0]*7
                mfccs = np.random.normal(mfcc_means, 6.0, 20)
                pitch = np.random.normal(145, 35)
                energy = np.random.normal(1.8, 0.5)
                centroid = np.random.normal(16.0, 3.0)
                zcr = np.random.normal(7.0, 2.0)
                rolloff = np.random.normal(17.0, 3.0)
                chroma = np.random.normal(0.5, 0.1, 12)

            features = np.concatenate([mfccs, [pitch, energy, centroid, zcr, rolloff], chroma])
            X.append(features)
            y.append(guna_idx)

    return np.array(X), np.array(y)


def main():
    print("==============================================================")
    print("            SVARA-SIDDHI MODEL EVALUATION REPORT              ")
    print("==============================================================\n")
    
    model_path = "svara_model.pkl"
    scaler_path = "svara_scaler.pkl"
    metadata_path = "model_metadata.json"
    
    metadata = {}
    if os.path.exists(metadata_path):
        try:
            with open(metadata_path, "r") as f:
                metadata = json.load(f)
        except Exception as e:
            print(f"Error loading model metadata: {e}")

    is_ravdess = metadata.get("model_type") == "ravdess"
    
    if is_ravdess:
        print("Active Model: Scientific Bio-Acoustic Classifier (RAVDESS Dataset)")
        print(f"Calibration Timestamp : {metadata.get('timestamp')}")
        print(f"Dataset Size          : {metadata.get('samples')} voice recordings")
        print(f"Trained Actors        : {metadata.get('actors_trained')} actors (1 to {metadata.get('actors_trained')})")
        print(f"Training Duration     : {metadata.get('training_duration_seconds')} seconds")
        print(f"Overall Model Accuracy: {metadata.get('accuracy', 0.0) * 100:.2f}%")
        
        print("\n----------------- Granular Evaluation Metrics -----------------")
        metrics = metadata.get("metrics", {})
        print("Guna State   | Precision | Recall    | F1-Score")
        print("-------------------------------------------------------")
        for guna in ["Tamasic", "Rajasic", "Sattvic"]:
            guna_metrics = metrics.get(guna, {})
            p = guna_metrics.get("precision", 0.0) * 100
            r = guna_metrics.get("recall", 0.0) * 100
            f1 = guna_metrics.get("f1-score", 0.0) * 100
            print(f"{guna:<12} | {p:>8.2f}% | {r:>8.2f}% | {f1:>8.2f}%")
            
        print("\n---------------- Top Feature Importances ----------------")
        for rank, item in enumerate(metadata.get("feature_importances", [])):
            print(f"{rank+1:02d}. {item['feature']:<20} : {item['importance'] * 100:.2f}%")
        print("==============================================================")
        return

    print("Active Model: Synthetic Bio-Acoustic Classifier (Wellness Baselines)")
    if os.path.exists(model_path) and os.path.exists(scaler_path):
        print("Loading svara_model.pkl from disk...")
        try:
            with open(model_path, "rb") as f:
                model = pickle.load(f)
            with open(scaler_path, "rb") as f:
                scaler = pickle.load(f)
        except Exception as e:
            print(f"Failed to load saved model: {e}. Falling back to clean training...")
            model, scaler = None, None
    else:
        model, scaler = None, None

    X, y = _generate_synthetic_data(n_samples=1800)
    
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    if model is None or scaler is None:
        scaler = StandardScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_test_scaled = scaler.transform(X_test)
        
        from sklearn.neural_network import MLPClassifier
        model = MLPClassifier(
            hidden_layer_sizes=(128, 64),
            activation="relu",
            solver="adam",
            max_iter=500,
            random_state=42,
            early_stopping=True
        )
        model.fit(X_train_scaled, y_train)
    else:
        X_test_scaled = scaler.transform(X_test)

    y_pred = model.predict(X_test_scaled)
    acc = accuracy_score(y_test, y_pred)
    
    print(f"Overall Model Validation Accuracy: {acc * 100:.2f}%")
    print("\n----------------- Classification Report -----------------")
    target_names = ["Tamasic", "Rajasic", "Sattvic"]
    print(classification_report(y_test, y_pred, target_names=target_names))
    
    print("----------------- Confusion Matrix -----------------")
    cm = confusion_matrix(y_test, y_pred)
    print("               Predicted")
    print("               T   R   S")
    for i, name in enumerate(target_names):
        print(f"Actual {name[0]}:   {cm[i][0]:3d} {cm[i][1]:3d} {cm[i][2]:3d}")
        
    print("\n---------------- Feature Importances (Top 10) ----------------")
    feature_names = (
        [f"MFCC_{i+1}" for i in range(40)]
        + [f"MFCC_Delta_{i+1}" for i in range(40)]
        + [f"MFCC_Delta2_{i+1}" for i in range(40)]
        + ["Pitch (F0)", "RMS Energy", "Spectral Centroid", "ZCR", "Spectral Rolloff"]
        + [f"Chroma_{i+1}" for i in range(12)]
        + [f"Mel_{i+1}" for i in range(128)]
        + [f"Contrast_{i+1}" for i in range(7)]
    )
    
    if hasattr(model, "feature_importances_"):
        importances = model.feature_importances_
    else:
        weights_sum = np.sum(np.abs(model.coefs_[0]), axis=1)
        importances = weights_sum / np.sum(weights_sum)
        
    indices = np.argsort(importances)[::-1]
    
    for rank in range(10):
        idx = indices[rank]
        print(f"{rank+1:02d}. {feature_names[idx]:<20} : {importances[idx] * 100:.2f}%")
    print("==============================================================")


if __name__ == "__main__":
    main()

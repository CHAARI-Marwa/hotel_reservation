from flask import Flask, request, jsonify
import torch
from PIL import Image
from facenet_pytorch import InceptionResnetV1, MTCNN
from torchvision import transforms
from sklearn.metrics.pairwise import cosine_similarity
import json
from werkzeug.utils import secure_filename
import os

app = Flask(__name__)

facenet_model = InceptionResnetV1(pretrained='vggface2').eval()
mtcnn = MTCNN()

transform = transforms.Compose([
    transforms.Resize((160, 160)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5])
])

def extract_face_features(image_path):
    image = Image.open(image_path).convert("RGB")
    aligned_image = mtcnn(image)
    if aligned_image is None:
        raise ValueError(f"Visage non détecté dans l'image {image_path}")
    aligned_image = aligned_image.unsqueeze(0)
    with torch.no_grad():
        features = facenet_model(aligned_image)
    return features.numpy().flatten()

FEATURES_DIRECTORY = 'features'

def save_features(features, filename):
    filepath = os.path.join(FEATURES_DIRECTORY, secure_filename(filename))
    with open(filepath, 'w') as f:
        json.dump(features, f)


@app.route('/extract_features', methods=['POST'])
def extract_features():
    try:
        if 'file' not in request.files:
            return jsonify({"error": "Aucun fichier envoyé"}), 400

        file = request.files['file']
        if file.filename == '':
            return jsonify({"error": "Nom de fichier invalide"}), 400

        image_path = f"./temp_{file.filename}"
        file.save(image_path)

        features = extract_face_features(image_path)

        import os
        os.remove(image_path)

        return jsonify({"features": features.tolist()})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    

@app.route('/receive_features', methods=['POST'])
def receive_features():
    try:
        features_data = request.form.get('features')
        if not features_data:
            return jsonify({'error': 'No features provided'}), 400
        
        features = json.loads(features_data)
        
        filename = 'received_features.json'
        save_features(features, filename)
        
        return jsonify({'message': 'Features received and saved successfully'}), 200
    except json.JSONDecodeError as e:
        return jsonify({'error': f'Invalid JSON format: {str(e)}'}), 400
    except Exception as e:
        return jsonify({'error': f'Server error: {str(e)}'}), 500


@app.route('/verify_person', methods=['POST'])
def verify_person():
    try:
        print("Début de la vérification de personne")
        if 'file' not in request.files:
            print("Aucun fichier dans la requête")
            return jsonify({"error": "Aucun fichier envoyé"}), 400

        file = request.files['file']
        if file.filename == '':
            print("Nom de fichier vide")
            return jsonify({"error": "Nom de fichier invalide"}), 400

        print(f"Fichier reçu: {file.filename}")

        if not os.path.exists('temp'):
            os.makedirs('temp')
            print("Dossier temp créé")

        temp_path = os.path.join('temp', secure_filename(file.filename))
        print(f"Sauvegarde temporaire dans: {temp_path}")
        file.save(temp_path)

        try:
            print("Extraction des caractéristiques...")
            query_features = extract_face_features(temp_path)
            print("Caractéristiques extraites avec succès")
        except ValueError as e:
            print(f"Erreur lors de l'extraction: {str(e)}")
            if os.path.exists(temp_path):
                os.remove(temp_path)
            return jsonify({"error": str(e)}), 400

        features_path = os.path.join(FEATURES_DIRECTORY, 'received_features.json')
        print(f"Chargement des caractéristiques depuis: {features_path}")
        
        if not os.path.exists(features_path):
            print("Fichier de caractéristiques non trouvé")
            if os.path.exists(temp_path):
                os.remove(temp_path)
            return jsonify({"error": "Aucune caractéristique de référence trouvée"}), 404

        try:
            with open(features_path, 'r') as f:
                reference_features = json.load(f)
            print(f"Caractéristiques chargées: {len(reference_features)} références trouvées")
        except json.JSONDecodeError as e:
            print(f"Erreur de décodage JSON: {str(e)}")
            if os.path.exists(temp_path):
                os.remove(temp_path)
            return jsonify({"error": "Erreur lors du chargement des caractéristiques"}), 500

        print("Début de la comparaison...")
        similarities = {}
        query_features_reshaped = query_features.reshape(1, -1)
        
        for name, features in reference_features.items():
            try:
                ref_features = torch.tensor(features).reshape(1, -1)
                similarity = cosine_similarity(query_features_reshaped, ref_features)[0][0]
                similarities[name] = float(similarity)
                # print(f"Similarité avec {name}: {similarity}")
                print("cette personne est autorisée")
            except Exception as e:
                print(f"Erreur lors de la comparaison avec {name}: {str(e)}")
                continue

        if os.path.exists(temp_path):
            os.remove(temp_path)
            print("Fichier temporaire supprimé")

        threshold = 0.8
        matches = [name for name, sim in similarities.items() if sim > threshold]
        print(f"Correspondances trouvées: {matches}")

        if matches:
            return jsonify({
                "status": "success",
                "message": "Personne identifiée",
                "matches": matches,
                "similarities": similarities
            }), 200
        else:
            return jsonify({
                "status": "failure",
                "message": "Aucune correspondance trouvée",
                "similarities": similarities
            }), 404

    except Exception as e:
        print(f"Erreur inattendue: {str(e)}")
        import traceback
        print(traceback.format_exc())
        return jsonify({"error": str(e)}), 500


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)

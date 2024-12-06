from flask import Flask, request, jsonify
import torch
from PIL import Image
from facenet_pytorch import InceptionResnetV1, MTCNN
from torchvision import transforms
import json

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

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)

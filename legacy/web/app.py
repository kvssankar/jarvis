import os
import json
import random
from flask import Flask, render_template, request, send_from_directory, jsonify
from core import Image, Collection, GeminiModel

app = Flask(__name__)
model = GeminiModel()

# Sample tags for demonstration
SAMPLE_TAGS = [
    "screenshot",
    "code",
    "social-media",
    "document",
    "website",
    "dark-mode",
    "light-mode",
    "mobile",
    "desktop",
    "chat",
    "email",
    "terminal",
    "browser",
    "text-editor",
    "music",
]

# Global storage for images and collections
images = []
collections = []

ALLOWED_IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp"}


@app.route("/", methods=["GET"])
def index():
    return render_template("index.html", images=images)


@app.route("/scan", methods=["POST"])
def scan_directory():
    global images
    data = request.json
    directory = data.get("path", os.getcwd())

    if not os.path.exists(directory):
        return jsonify({"success": False, "error": "Directory does not exist"}), 400

    images.clear()  # Clear existing images

    for root, _, files in os.walk(directory):
        for file in files:
            if os.path.splitext(file)[1].lower() in ALLOWED_IMAGE_EXTENSIONS:
                abs_path = os.path.abspath(os.path.join(root, file))
                img = Image(abs_path)
                if img not in images:
                    images.append(img)
    return jsonify({"success": True, "count": len(images)})


@app.route("/process", methods=["POST"])
def process_images():
    """
    Example JSON response from process_images:
    [
        {
            'filename': 'test/Screenshot from 2025-05-15 17-11-28.png',
            'desc': "This screenshot shows a signature with the name 'XXXX' and the date 15/05/2025.",
            'tags': ['signature', 'date', '2025', 'handwritten'],
            'other': []
        },
        {
            'filename': 'test/Screenshot from 2025-04-02 17-26-09.png',
            'desc': 'A black and white portrait of Jennie Kim.',
            'tags': ['Jennie Kim', 'portrait', 'black and white', 'kpop', 'singer'],
            'other': []
        }
    ]
    """
    global images, collections

    try:
        result, status_code = model.process_images(images)

        if status_code != 200:
            return (
                jsonify({"success": False, "error": "Processing failed"}),
                status_code,
            )

        data = model.extract_command(result)
        json_result = data

        print("\n\n Got the response")

        for image in json_result:
            filename = image.get("filename")
            desc = image.get("desc")
            tags = image.get("tags", [])
            other = image.get("other", [])

            img = next((img for img in images if img.filename == filename), None)
            if img and not img.processed:
                img.set_description(desc)
                img.add_tags(tags)
                # img.other = other
                img.processed = True
                print(f"\n\n\n\nProcessed image: {filename}")
            else:
                print(f"Image {filename} already processed, skipping.")

        return jsonify({"success": True})

    except json.JSONDecodeError:
        print("Error parsing JSON response:", result)
        return jsonify({"success": False, "error": "Error parsing JSON response"}), 500
    except Exception as e:
        print("Unexpected error:", str(e))
        return jsonify({"success": False, "error": f"some unknown error occured"}), 500


@app.route("/user_files/<path:filename>")
def serve_user_file(filename):
    if ".." in filename:
        app.logger.warning(f"serve_user_file: Invalid filename attempt: '{filename}'")
        return "Invalid filename", 400

    try:
        # Ensure we have an absolute path by adding leading / if missing
        abs_path = filename if filename.startswith("/") else f"/{filename}"
        directory = os.path.dirname(abs_path)
        basename = os.path.basename(abs_path)
        print(f"Serving file: {abs_path} from directory: {directory}")
        return send_from_directory(directory, basename)
    except Exception as e:
        app.logger.error(f"Error serving file '{filename}': {e}", exc_info=True)
        raise


@app.route("/collections", methods=["GET"])
def list_collections():
    return jsonify(
        {
            "collections": [
                {
                    "name": c.name,
                    "count": c.get_image_count(),
                    "preview": (
                        c.get_preview_image().path if c.get_preview_image() else None
                    ),
                }
                for c in collections
            ]
        }
    )


@app.route("/collections/create", methods=["POST"])
def create_collection():
    global collections
    data = request.json
    name = data.get("name")
    description = data.get("description", "")

    if not name:
        return jsonify({"success": False, "error": "Name is required"}), 400

    # Check if collection with this name already exists
    if any(c.name == name for c in collections):
        return jsonify({"success": False, "error": "Collection already exists"}), 400

    # Create new collection
    collection = Collection(name)
    collection.set_description(description)
    collections.append(collection)

    return jsonify({"success": True})


@app.route("/image/<path:filename>/details")
def get_image_details(filename):
    img_name = os.path.basename(filename)
    image = next((img for img in images if img.filename == img_name), None)

    if not image:
        return jsonify({"error": "Image not found"}), 404

    # Find collections containing this image
    image_collections = [c.name for c in collections if image in c.images]

    return jsonify(
        {
            "filename": image.filename,
            "path": image.path,
            "tags": image.get_tags(),
            "collections": image_collections,
        }
    )


@app.route("/collections/<name>")
def view_collection(name):
    collection = next((c for c in collections if c.name == name), None)
    if not collection:
        return "Collection not found", 404
    return render_template("collection.html", collection=collection)


@app.route("/image/<path:filename>/update_collections", methods=["POST"])
def update_image_collections(filename):
    data = request.json
    collection_names = data.get("collections", [])

    img_name = os.path.basename(filename)
    image = next((img for img in images if img.filename == img_name), None)

    if not image:
        return jsonify({"error": "Image not found"}), 404

    # Remove image from all collections first
    for collection in collections:
        if image in collection.images:
            collection.remove_image(image)
            image.collections.remove(collection)

    # Add image to selected collections
    for collection_name in collection_names:
        collection = next((c for c in collections if c.name == collection_name), None)
        if collection:
            collection.add_image(image)
            image.collections.append(collection)

    return jsonify({"success": True})


if __name__ == "__main__":
    app.run(debug=True)

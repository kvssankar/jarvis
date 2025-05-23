import base64
import datetime
import json
import os
import requests


class Image:
    def __init__(self, path: str):
        self.filename = os.path.basename(path)
        self.path = path

        # metadata
        self.size = os.path.getsize(path)
        self.created_at = datetime.datetime.now()
        self.modified_at = datetime.datetime.now()
        self.tags = []
        self.description = ""
        self.collections = []

        self.processed = False

    def __eq__(self, other):
        if not isinstance(other, Image):
            return False
        return self.path == other.path

    def get_info(self):
        return {
            "filename": self.filename,
            "path": self.path,
            "size": self.size,
            "created_at": self.created_at,
            "modified_at": self.modified_at,
            "tags": self.tags,
            "description": self.description,
            "collections": [c.name for c in self.collections],
        }

    def update_metadata(self):
        self.size = os.path.getsize(self.path)
        self.modified_at = datetime.datetime.now()

    def add_tag(self, tag: str):
        self.tags.append(tag)
        self.update_metadata()
    
    def add_tags(self, tags: list):
        for tag in tags:
            if tag not in self.tags:
                self.tags.append(tag)
        self.update_metadata()

    def get_tags(self):
        return self.tags
    
    def set_description(self, description: str):
        self.description = description
        self.update_metadata()
    
    def get_description(self):
        return self.description
    
    def get_collections(self):
        return self.collections
    


class Collection:
    def __init__(self, name: str):
        self.name = name
        self.images = []
        self.created_at = datetime.datetime.now()
        self.description = ""
        self.last_updated = datetime.datetime.now()

    def add_image(self, image: Image):
        if image not in self.images:
            self.images.append(image)

    def remove_image(self, image: Image):
        if image in self.images:
            self.images.remove(image)

    def get_image_count(self):
        return len(self.images)

    def get_preview_image(self):
        return self.images[0] if self.images else None

    def set_description(self, description: str):
        self.description = description
        self.update_metadata()

    def update_metadata(self):
        self.last_updated = datetime.datetime.now()


class GeminiModel:
    base_url = "https://generativelanguage.googleapis.com/v1beta/models"
    timeout = 30

    def __init__(self, model_name: str = "gemini-2.0-flash"):
        self.model_name = model_name
        self.api_key = os.getenv("GEMINI_API_KEY")
        if not self.api_key:
            raise ValueError("GEMINI_API_KEY environment variable is not set")

    def process_images(self, images):
        if not images:
            return "No images to process.", 400

        print(f"Processing {len(images)} images...")
        request_data, headers = self._prepare_request_data(images)

        try:
            response, status_code = self.fetch_ai_response(request_data, headers)
            if status_code != 200:
                return f"Error: {response}", status_code
            return response, status_code
        except Exception as e:
            return f"Error processing images: {str(e)}", 500

    def fetch_ai_response(self, request_data, headers):
        url = f"{self.base_url}/{self.model_name}:generateContent?key={self.api_key}"

        try:
            response = requests.post(
                url, headers=headers, json=request_data, timeout=self.timeout
            )
            response_json = response.json()

            ai_response_text = (
                response_json.get("candidates", [{}])[0]
                .get("content", {})
                .get("parts", [{}])[0]
                .get("text", None)
            )

            if not ai_response_text:
                return "No response from AI", response.status_code

            return ai_response_text, response.status_code

        except requests.Timeout:
            return "Request timed out", 408
        except requests.RequestException as e:
            return f"Error making request: {str(e)}", 500
        except Exception as e:
            return f"Unexpected error: {str(e)}", 500

    def _prepare_request_data(self, images):
        content_parts = [{"text": self.get_prompt()}]

        for image in images:
            content_parts.append({"text": f"\nAnalyzing image: {image.path}"})
            image_data = self.convert_image_to_base64(image.path)
            content_parts.append({"inline_data": image_data})

        request_data = {"contents": [{"parts": content_parts}]}
        headers = {"Content-Type": "application/json"}

        return request_data, headers

    def convert_image_to_base64(self, image_path):
        with open(image_path, "rb") as f:
            encoded = base64.b64encode(f.read()).decode("utf-8")
        mime_type = "image/jpeg" if image_path.lower().endswith(".jpg") else "image/png"
        return {"mime_type": mime_type, "data": encoded}

    def get_prompt(self):
        return (
            "You are a screenshot analyzer. You will be given single or multiple images. "
            "For each image, generate a short description and 3-5 relevant tags "
            "with which users can search and find later with ease.\n"
            "Respond strictly in this JSON format:\n"
            "{filename: '', desc: '', tags: [], other: []}, ..."
        )
    
    def extract_command(self, query: str) -> tuple:
        """
        Extract text and commands from a text structure in valid JSON format:

        {
          "text": "<NORMAL_TEXT>",
          "commands": ["<bash command 1>", "<bash command 2>", ...]
        }

        Returns:
            tuple of (text, [list of commands])
        """
        query = query.strip()
        if not query.startswith("```json"):
            return query, []
        query = query.replace("```json", "").replace("```", "").strip()

        try:
            data = json.loads(query)

            return data

        except Exception as e:
            print(f"Error processing query: {e}")
            return "", []


if __name__ == "__main__":
    model = GeminiModel()

    test_images = [
        Image("test/image1.png"),
        Image("test/image2.png"),
    ]

    print(f"Processing {len(test_images)} images...")
    result, status_code = model.process_images(test_images)

    if status_code == 200:
        try:
            json_result = json.loads(result)
            print("\nResults:")
            for item in json_result:
                print(f"\nFilename: {item.get('filename', 'Unknown')}")
                print(f"Description: {item.get('desc', 'No description')}")
                print(f"Tags: {', '.join(item.get('tags', []))}")
        except json.JSONDecodeError:
            print("Error parsing JSON response:", result)
    else:
        print(f"Error ({status_code}):", result)

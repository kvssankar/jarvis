import os
import datetime


class Image:
    def __init__(self, path: str):
        self.filename = os.path.basename(path)
        self.path = path
        
        # metadata
        self.size = os.path.getsize(path)
        self.created_at = datetime.datetime.now()
        self.modified_at = datetime.datetime.now()
        self.tags = []
        
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
        }

    def update_metadata(self):
        self.size = os.path.getsize(self.path)
        self.modified_at = datetime.datetime.now()

    def add_tag(self, tag: str):
        self.tags.append(tag)
        self.update_metadata()

    def get_tags(self):
        return self.tags


class Collection:
    def __init__(self, name: str):
        self.name = name
        self.images = []
        self.created_at = datetime.datetime.now()
        
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

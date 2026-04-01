from post.models import PostImage
from rest_framework import serializers
class PostImageSerializer(serializers.ModelSerializer):
    image = serializers.FileField(use_url=True)

    class Meta:
        model = PostImage
        fields = [
            'id',
            'image',
        ]
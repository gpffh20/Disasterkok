from django.contrib import admin
from post.models import Post, PostImage, PostLike, PostTag, Tag

admin.site.register(Post)
admin.site.register(PostImage)
admin.site.register(PostLike)
admin.site.register(PostTag)
admin.site.register(Tag)

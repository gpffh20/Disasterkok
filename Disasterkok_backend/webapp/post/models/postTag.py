from django.db import models
from post.models import Post, Tag


class PostTag(models.Model):
    post = models.ForeignKey(Post, on_delete=models.CASCADE)
    tag = models.ForeignKey(Tag, on_delete=models.CASCADE)

    class Meta:
        db_table = 'posttag'
        verbose_name = 'PostTag'
        verbose_name_plural = 'PostTags'
from rest_framework import serializers
from ..models import User


class LoginSerializer(serializers.ModelSerializer):
    class Meta:
        model = User

        fields = [
            'username',
            'password',
        ]

        extra_kwargs = {
            'password': {
                'write_only': True
            }
        }
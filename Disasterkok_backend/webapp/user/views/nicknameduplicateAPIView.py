from rest_framework.decorators import permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from user.models import User

@permission_classes([AllowAny])
class DuplicateNickameAPIView(APIView):
    def post(self, request):
        nickname = request.data.get('nickname')
        if nickname is None:
            return Response({'message': '닉네임을 입력해주세요.'}, status=400)
        if User.objects.filter(nickname=nickname).exists():
            return Response({'message': '존재하는 닉네임입니다.'}, status=400)
        return Response({'message': '가능한 닉네임입니다.'}, status=200)

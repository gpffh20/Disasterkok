from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import RefreshToken


class LogoutAPIView(APIView):
    def post(self, request):
        # 쿠키에서 토큰 가져와서 바로 지움
        refresh_token = request.COOKIES.get("refresh")

        if refresh_token:
            try:
                token = RefreshToken(refresh_token)
                token.blacklist()
                return Response({"message": "로그아웃 성공",
                                 "deleted_token": refresh_token},
                                status=status.HTTP_200_OK)
            except TokenError:
                return Response({"message": "유효하지 않은 토큰입니다."},
                                status=status.HTTP_400_BAD_REQUEST)
        return Response({"message": "Refresh 토큰이 필요합니다."},
                        status=status.HTTP_400_BAD_REQUEST)

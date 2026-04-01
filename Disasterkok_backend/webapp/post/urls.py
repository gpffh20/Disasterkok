from django.urls import path
from . import views


urlpatterns = [
    path('', views.PostListAPIView.as_view(), name='post-list'),
    path('<int:post_id>/', views.PostDetailAPIView.as_view(), name='post-detail'),
    path('<int:post_id>/likes/', views.PostLikeAPIView.as_view(), name='likes'),
    path('home/', views.PostAtHomeTopSixAPIView.as_view(), name='home'),
]

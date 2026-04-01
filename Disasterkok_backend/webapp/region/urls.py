from django.urls import path

from region.views import *

urlpatterns = [
    path('', RegionListCreateAPIView.as_view()),
    path('<int:region_id>/', RegionRetrieveUpdateDestroyAPIView.as_view()),
    path('<int:region_id>/default/', RegionDefaultAPIView.as_view()),
    path('<int:region_id>/onoff/', RegionOnOffAPIView.as_view()),
]

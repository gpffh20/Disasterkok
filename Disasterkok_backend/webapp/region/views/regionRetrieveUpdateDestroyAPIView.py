from rest_framework.generics import RetrieveUpdateDestroyAPIView

from region.models import Region
from region.serializers import RegionRetrieveSerializer


class RegionRetrieveUpdateDestroyAPIView(RetrieveUpdateDestroyAPIView):
    queryset = Region.objects.all()
    serializer_class = RegionRetrieveSerializer
    lookup_url_kwarg = 'region_id'


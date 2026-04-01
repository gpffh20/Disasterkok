from rest_framework import serializers

from region.models import Region


class RegionRetrieveSerializer(serializers.ModelSerializer):
    class Meta:
        model = Region
        fields = (
            'aliasType',
            'name',
        )
        read_only_fields = (
            'id',
            'onOff',
            'default',
            'address',
            'roadAddress',
            'zoneCode',
            'xCoordinate',
            'yCoordinate',
        )

    def to_representation(self, instance):
        data = super().to_representation(instance)

        for field in self.Meta.read_only_fields:
            data[field] = getattr(instance, field)

        return data
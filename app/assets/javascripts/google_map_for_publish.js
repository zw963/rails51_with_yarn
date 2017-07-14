(function() {
    window.page__shared__google_map_for_publish = {};

    function init() {
        $('.js-google-map-container').each(function() {
            var mapContainer = $(this);

            var mapId = mapContainer.data('google-map-id');
            var centerLat = mapContainer.find('.js-lat').val();
            var centerLng = mapContainer.find('.js-lng').val();
            var zoom = mapContainer.data('google-map-zoom');
            var titleText = mapContainer.data('title-text');
            var map = new GMaps({
                div: '#' + mapId,
                lat: centerLat,
                lng: centerLng,
                zoom: zoom,
                zoom_changed: function () {
                    var lat = this.center.lat();
                    var lng = this.center.lng();
                    setAddress(lat, lng);
                },
                dragstart: function () {
                    map.removeMarkers();
                },
                dragend: function () {
                    var lat = this.center.lat();
                    var lng = this.center.lng();
                    addMarker(lat, lng);
                }
            });

            var setAddress = function (lat, lng) {
                // 填充 lat, lng 的值
                mapContainer.find('.js-lat').val(lat);
                mapContainer.find('.js-lng').val(lng);
                // 设置地图以 lat, lng 居中.
                map.setCenter(lat, lng);
                // 发送请求, 转化 lat lng 为真实地址.
                var url = mapContainer.data('google-map-geocode-to-address-url');
                $.get(url, {lat: lat, lng: lng}, function (json) {
                    mapContainer.find('.js-address').val(json.address);
                }, 'json');
            };

            var addMarker = function (lat, lng) {
                map.addMarker({
                    lat: lat,
                    lng: lng,
                    title: titleText,
                    draggable: true,
                    dragend: function () {
                        var lat = this.getPosition().lat();
                        var lng = this.getPosition().lng();
                        setAddress(lat, lng);
                    }
                });
                setAddress(lat, lng);
            };
            addMarker(centerLat, centerLng);

            GMaps.geolocate({
                success: function(position) {
                    var lat = position.coords.latitude;
                    var lng = position.coords.longitude;
                    addMarker(lat, lng);
                },
                error: function(error) {
                },
                not_supported: function() {
                },
                always: function() {
                }
            });

        });
    }

    window.page__shared__google_map_for_publish.init = init;
}).call(this);

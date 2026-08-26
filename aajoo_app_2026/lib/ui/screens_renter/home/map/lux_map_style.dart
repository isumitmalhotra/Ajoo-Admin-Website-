// The map, in LUX.
//
// The website darkens its tiles in LUXE with a CSS filter
// (`[data-lux] .leaflet-tile{filter:invert(1) hue-rotate(180deg) …}`), because
// a daylight street map is the single largest bright object on the screen and
// leaving it lit undoes the whole mode. The app had no equivalent: switching
// to LUX turned the sheet black and left a white map filling the top half of
// the home screen behind it.
//
// Google Maps has no filter, so this is a style array instead — the same
// intent expressed in the only vocabulary the SDK has. It is built from the
// LUX palette rather than a stock "night mode": the ground is the page colour
// (#0A0A0C), water is a shade off it, and roads and labels step up through the
// surface greys, with the gold reserved for nothing at all — the pins are the
// only gold on the map, so they stay the thing your eye goes to.
//
// Passed to GoogleMap's `style:` parameter (google_maps_flutter ≥ 2.6), not
// the deprecated setMapStyle.
const String luxMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0A0A0C"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#A6A39C"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0A0A0C"}]},
  {"featureType":"administrative","elementType":"geometry",
   "stylers":[{"color":"#2A2A2E"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill",
   "stylers":[{"color":"#8C887E"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill",
   "stylers":[{"color":"#C9C4B8"}]},
  {"featureType":"poi","elementType":"labels.text.fill",
   "stylers":[{"color":"#77746D"}]},
  {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry",
   "stylers":[{"color":"#14181A"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill",
   "stylers":[{"color":"#5E6B60"}]},
  {"featureType":"road","elementType":"geometry",
   "stylers":[{"color":"#1A1A1D"}]},
  {"featureType":"road","elementType":"geometry.stroke",
   "stylers":[{"color":"#141416"}]},
  {"featureType":"road","elementType":"labels.text.fill",
   "stylers":[{"color":"#8C887E"}]},
  {"featureType":"road.arterial","elementType":"geometry",
   "stylers":[{"color":"#242428"}]},
  {"featureType":"road.highway","elementType":"geometry",
   "stylers":[{"color":"#33302A"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke",
   "stylers":[{"color":"#3D3830"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill",
   "stylers":[{"color":"#C2BCAE"}]},
  {"featureType":"transit","elementType":"geometry",
   "stylers":[{"color":"#1F1F23"}]},
  {"featureType":"transit.station","elementType":"labels.text.fill",
   "stylers":[{"color":"#8C887E"}]},
  {"featureType":"water","elementType":"geometry",
   "stylers":[{"color":"#0E1114"}]},
  {"featureType":"water","elementType":"labels.text.fill",
   "stylers":[{"color":"#4A5560"}]}
]
''';

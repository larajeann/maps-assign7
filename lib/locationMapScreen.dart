import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  MapScreen({Key? key}) : super(key: key);

  static final initialPosition = LatLng(15.987759983041407, 120.57320964570188);


  @override
  State<MapScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  var descController = TextEditingController();
  late CollectionReference favoritePlaces =
      FirebaseFirestore.instance.collection('favorite_places');

 Future<bool> checkServicePermission() async {
    bool isEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar( content: Text('Location services is disabled. Please enable it in the settings.')));
      return false;
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(  'Location permission is denied. Please accept the location permission of the app to continue.'),),
          );
        }
        return false;
    }
     if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text( 'Location permission is permanently denied. Please change in the settings to continue.')),
        );
        return false;
      }
    return true;
  }

  void setToLocation(LatLng position) {
    markers.clear();
    markers.add(
      Marker(
        markerId: MarkerId('$position'),
        position: position,
        infoWindow: InfoWindow(title: 'Pinned'),
      ),
    );
    CameraPosition cameraPosition = CameraPosition(target: position, zoom: 15);
    mapController.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    setState(() {});
  }
  void getCurrentLocation() async {
    if (!await checkServicePermission()) {
      return;
    }
    Geolocator.getPositionStream(locationSettings: LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10,
    )).listen((position) {
      setToLocation(LatLng(position.latitude, position.longitude));
    });
  }
 void addMarker(LatLng position, String description) {
  markers.add(
    Marker(
      markerId: MarkerId(position.toString()),
      position: position,
      infoWindow: InfoWindow(
        title: 'Pinned',
        snippet: description,
      ),
      onTap: () => delete(position, description),
    ),
  );
  setState(() {});
}

void delete(LatLng position, String description) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(description),
        content: Text('Do you want to remove this pinned location?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              deleteFavoritePlace(position.toString());
              Navigator.of(context).pop();
            },
            child: Text('Remove'),
          ),
        ],
      );
    },
  );
}

void deleteFavoritePlace(String markerId) async {
  markers.removeWhere((marker) => marker.markerId.value == markerId);
  setState(() {});
  await favoritePlaces
      .where('markerId', isEqualTo: markerId)
      .get()
      .then((snapshot) {
    snapshot.docs.forEach((doc) {
      doc.reference.delete();
    });
  });
}

void loadFavoritePlaces() async {
  QuerySnapshot querySnapshot = await favoritePlaces.get();
  querySnapshot.docs.forEach((doc) {
    var location = doc['location'];
    if (location != null && location is Map<String, dynamic> && location.containsKey('latitude') && location.containsKey('longitude')) {
      double lat = location['latitude'];
      double lng = location['longitude'];
      LatLng position = LatLng(lat, lng);
      String description = doc['description'] ?? ''; 
      addMarker(position, description);
    } else {
      print('Invalid location data in Firestore document: ${doc.id}');
    }
  });
}

 @override
  void initState() {
    super.initState();
   // getCurrentLocation();
    loadFavoritePlaces();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: MapScreen.initialPosition,
          zoom: 8,
        ),
        mapType: MapType.hybrid,
        zoomControlsEnabled: true,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onTap: (position) {
          print(position);
          descInput(position);
        },
        markers: markers,
        onMapCreated: (controller) {
          mapController = controller;
        },
      ),
    );
  }
void descInput(LatLng position) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: TextField(
          controller: descController,
          decoration: InputDecoration(hintText: ' Pin Description'),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () {
              saveFavoritePlace(position, descController.text);
              addMarker(position, descController.text);
              Navigator.of(context).pop();
              descController.clear();
            },
          ),
        ],
      );
    },
  );
}
  void saveFavoritePlace(LatLng position, String description) {
    favoritePlaces.add({'location': {'latitude': position.latitude, 'longitude': position.longitude}, 'description': description});
  }
}

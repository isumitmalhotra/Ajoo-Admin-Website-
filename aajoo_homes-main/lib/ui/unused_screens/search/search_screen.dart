import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/search_controller.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/ui/screens_renter/property_details/property_page.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryController = TextEditingController();
  final _focusNode = FocusNode(); // FocusNode added
  final searchController = Get.find<HomeSearchController>();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  void _search() async {
    searchController.query.value = _queryController.text;
    await searchController.searchProperty();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Properties"),
        backgroundColor: kprimaryColor,
        foregroundColor: kcontentColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _queryController,
              focusNode: _focusNode, // Attach the focus node
              decoration: InputDecoration(
                hintText: "Search by city, area, or property name",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => _search(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (searchController.searchResponse.value == null) {
                  return const Center(child: Text("Search for properties"));
                }
                if (searchController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (searchController.searchResponse.value!.data.isEmpty) {
                  return const Center(child: Text("No results found"));
                }
                return ListView.builder(
                  itemCount: searchController.searchResponse.value!.data.length,
                  itemBuilder: (context, index) {
                    final property =
                        searchController.searchResponse.value!.data[index];
                    return GestureDetector(
                      child: Card(
                        color: Colors.white,
                        child: ListTile(
                            leading: Container(
                              width: 100,
                              height: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: property.coverImage != null
                                      ? NetworkImage(property.coverImage!)
                                      : const AssetImage("assets/logo.png")
                                          as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(property.propertyName.toString(),
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const Divider(),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property.propertyAddress.toString(),
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.bold),
                                ),
                                // show price in a container
                                const SizedBox(
                                  height: 12,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: kprimaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Starting from Rs.${property.propertyPrice}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                )
                              ],
                            ),
                            onTap: () {
                              // Normalize dynamic lists to List<String>
                              final List<String> imagesSafe =
                                  (property.images ?? [])
                                      .map((e) => e.toString())
                                      .toList();
                              final List<String> categoryTitlesSafe = () {
                                final ct = property.categoryTitles;
                                if (ct == null) return <String>[];
                                if (ct is List) {
                                  return ct.map((e) => e.toString()).toList();
                                }
                                // Fallback: single string or unexpected type
                                return <String>[ct.toString()];
                              }();

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PropertyPage(
                                    property: Property(
                                      propertyId: property.propertyId,
                                      propertyName: property.propertyName ??
                                          "Unnamed Property",
                                      propertyAddress:
                                          property.propertyAddress ??
                                              "No address",
                                      propertyDesc: property.propertyDesc ??
                                          "No description",
                                      propertyPrice:
                                          property.propertyPrice ?? "0.0",
                                      propertyCity: property.propertyCity ??
                                          "Unknown City",
                                      propertyLongitude:
                                          property.propertyLongitude ?? "0",
                                      propertyLatitude:
                                          property.propertyLatitude ?? "0",
                                      propertyHostId: property.propertyHostId,
                                      propertyZip: property.propertyZip,
                                      propertyContact: property.propertyContact,
                                      propDetailsPropDetailIsPetFriendly: property
                                          .propDetailsPropDetailIsPetFriendly,
                                      propDetailsPropDetailIsSmoke:
                                          property.propDetailsPropDetailIsSmoke,
                                      propDetailsPropDetailInTime:
                                          property.propDetailsPropDetailInTime,
                                      propDetailsPropDetailOutTime:
                                          property.propDetailsPropDetailOutTime,
                                      propDetailsPropDetailExtra:
                                          property.propDetailsPropDetailExtra,
                                      coverImage: property.coverImage,
                                      images: imagesSafe,
                                      categoryTitles: categoryTitlesSafe,
                                    ),
                                    price: property.propertyPrice.toString(),
                                    name: property.propertyName.toString(),
                                    location:
                                        property.propertyAddress.toString(),
                                    image: property.coverImage.toString(),
                                    id: property.propertyId!,
                                    rating: "4.5",
                                    description:
                                        property.propertyDesc.toString(),
                                    lat: property.propertyLatitude.toString(),
                                    long: property.propertyLongitude.toString(),
                                    galleryImages: imagesSafe,
                                    inTime: property.propDetailsPropDetailInTime
                                        .toString(),
                                    outTime: property
                                        .propDetailsPropDetailOutTime
                                        .toString(),
                                  ),
                                ),
                              );
                            }),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

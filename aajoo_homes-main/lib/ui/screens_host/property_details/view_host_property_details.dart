import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rent_home/constants.dart';
import 'dart:io';

import 'package:rent_home/ui/screens_host/host_controller.dart';
import 'package:rent_home/data/models/host_properties_reponse.dart';

class HostPropertyDetails extends StatefulWidget {
  final Property property;

  const HostPropertyDetails({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  State<HostPropertyDetails> createState() => _HostPropertyDetailsState();
}

class _HostPropertyDetailsState extends State<HostPropertyDetails> {
  final HostController hostController = Get.find<HostController>();
  late bool isActive;
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    _picker.pickImage(source: ImageSource.gallery).then((value) {
      if (value != null) {
        setState(() {
          hostController.coverImage.value = File(value.path);
          coverImage = value;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    isActive = widget.property.isActive;
  }

  XFile? coverImage;
  @override
  Widget build(BuildContext context) {
    print(widget.property.propertyId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Property Details'),
        backgroundColor: kprimaryColor,
        foregroundColor: kcontentColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image
              widget.property.coverImage != null
                  ? SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: coverImage != null
                          ? Image.file(
                              File(coverImage!.path),
                              height: 250,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              widget.property.coverImage!,
                              height: 250,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    )
                  : coverImage != null
                      ? Image.file(
                          File(coverImage!.path),
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 250,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_sharp,
                                  color: Colors.grey[400]),
                              const Text(
                                "No Cover Image",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
              const SizedBox(height: 16),
              // update cover image
              TextButton(
                onPressed: () async {
                  await _pickImage();
                },
                child: const Text("Change/Update Cover Image"),
              ),
              //update cover image button
              Visibility(
                visible: coverImage != null,
                child: ElevatedButton(
                  onPressed: () async {
                    if (hostController.coverImage.value == null) return;
                    await hostController
                        .updateCoverImage(widget.property.propertyId!)
                        .then((value) {
                      hostController.getHostProperties();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      backgroundColor: kprimaryColor,
                      minimumSize: Size(200, 40),
                      foregroundColor: kcontentColor),
                  child: Obx(() => hostController.loading.value
                      ? const CircularProgressIndicator(
                          color: kcontentColor,
                        )
                      : const Text("Update Cover Image")),
                ),
              ),
              Text(
                "Property Id:" + widget.property.propertyId.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w200,
                ),
              ),
              const SizedBox(width: 30),
              // Property Name
              Text(
                widget.property.propertyName,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Property Description
              Text(
                widget.property.propertyDesc,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              // Property Address
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.property.propertyAddress,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Property Price
              _buildDetailRow("Price:", "₹${widget.property.propertyPrice}",
                  color: Colors.green),
              const SizedBox(height: 8),

              // Min Price
              _buildDetailRow(
                  "Min. Price:", "₹${widget.property.propertyMiniPrice}",
                  color: Colors.blue),
              const SizedBox(height: 16),

              // Property Images
              const Text(
                "Property Images:",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              widget.property.images.isNotEmpty
                  ? SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.property.images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Image.network(
                              widget.property.images[index],
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    )
                  : const Text("No images available"),
              const SizedBox(height: 16),
              //change the status of the property with switch button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Update the Property Status:",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Container(
                    constraints: const BoxConstraints(
                      maxWidth: 150,
                    ),
                    child: Switch(
                      value: isActive,
                      onChanged: (value) async {
                        //show confirm dialog box
                        await showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => Obx(
                                  () => hostController.loading.value
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: kprimaryColor,
                                          ),
                                        )
                                      : AlertDialog(
                                          title: const Text(
                                              "Update Property Status"),
                                          content: const Text(
                                              "Are you sure you want to change the status of this property?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                                onPressed: () async {
                                                  await hostController
                                                      .updatePropertyStatus(
                                                          widget.property
                                                              .propertyId!,
                                                          value ? 1 : 0)
                                                      .then((value) {
                                                    hostController
                                                        .getHostProperties();
                                                  });

                                                  Navigator.of(context).pop();
                                                  hostController
                                                      .getHostProperties();

                                                  setState(() {
                                                    isActive = value;
                                                  });
                                                },
                                                child: isActive
                                                    ? Text("Change to Inactive")
                                                    : Text("Change to Active")),
                                          ],
                                        ),
                                ));
                      },
                      activeColor: Colors.green,
                      activeTrackColor: Colors.green[100],
                      inactiveThumbColor: Colors.red,
                      inactiveTrackColor: Colors.red[100],
                    ),
                  )
                ],
              ),

              // Additional Information
              const Text(
                "Additional Information:",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                  "Pet Friendly: ${widget.property.propDetailsPropDetailIsPetFriendly ?? false ? 'Yes' : 'No'}"),
              Text(
                  "Smoking Allowed: ${widget.property.propDetailsPropDetailIsSmoke ?? false ? 'Yes' : 'No'}"),
              Text(
                  "Check-in Time: ${widget.property.propDetailsPropDetailInTime ?? 'Not provided'}"),
              Text(
                  "Check-out Time: ${widget.property.propDetailsPropDetailOutTime ?? 'Not provided'}"),
              const SizedBox(height: 16),

              // Contact Information
              const Text(
                "Contact Information:",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("Email: ${widget.property.propertyEmail ?? 'Not provided'}"),
              Text(
                  "Phone: ${widget.property.propertyContact ?? 'Not provided'}"),
              const SizedBox(height: 16),

              // Buttons
              Row(
                children: [
                  TextButton(
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        foregroundColor: kprimaryColor),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Close"),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () async {
                      // show delete confirmation dialog
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete Property"),
                          content: const Text(
                              "Are you sure you want to delete this property?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () async {
                                await hostController
                                    .deleteProperty(widget.property.propertyId!)
                                    .then(
                                      (value) => Navigator.of(context).pop(),
                                    );

                                Navigator.of(context).pop();
                                hostController.getHostProperties();
                              },
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: kprimaryColor,
                        foregroundColor: kcontentColor),
                    child: Obx(() => hostController.loading.value
                        ? const CircularProgressIndicator()
                        : const Text("Delete this Property")),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 14, color: color),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service class for handling listing operations with Supabase
class ListingService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Uploads a single image to Supabase Storage and returns the public URL
  static Future<String> uploadImageToSupabase(
      File imageFile, String fileName) async {
    try {
      // Upload the file to the propertyphotos bucket
      await _supabase.storage
          .from('propertyphotos')
          .upload(fileName, imageFile);

      // Get the public URL
      final publicUrl =
          _supabase.storage.from('propertyphotos').getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Uploads multiple images to Supabase Storage and returns their public URLs
  static Future<List<String>> uploadImagesToSupabase(
      List<String> imagePaths) async {
    try {
      List<String> uploadedUrls = [];

      for (int i = 0; i < imagePaths.length; i++) {
        final imageFile = File(imagePaths[i]);

        // Generate unique filename using timestamp and index
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = path.extension(imagePaths[i]);
        final fileName = 'property_${timestamp}_$i$extension';

        // Upload image and get URL
        final publicUrl = await uploadImageToSupabase(imageFile, fileName);
        uploadedUrls.add(publicUrl);

        // Add small delay to prevent overwhelming the server
        await Future.delayed(const Duration(milliseconds: 100));
      }

      return uploadedUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  /// Creates a new listing in the Supabase database
  static Future<Map<String, dynamic>> createListing({
    required String propertyType,
    required double price,
    required String location,
    required List<String> photos,
    required List<String> amenities,
    String? title,
    String? description,
    String? area,
    String? address,
    LatLng? coordinates,
  }) async {
    try {
      // Prepare the listing data
      final listingData = {
        'property_type': propertyType,
        'price': price,
        'location': location,
        'photos': photos, // This will be stored as JSON array
        'amenities': amenities, // This will be stored as JSON array
        'created_at': DateTime.now().toIso8601String(),
      };

      // Add optional fields if provided
      if (title != null) listingData['title'] = title;
      if (description != null) listingData['description'] = description;
      if (area != null) listingData['area'] = area;
      if (address != null) listingData['address'] = address;
      if (coordinates != null) {
        listingData['latitude'] = coordinates.latitude;
        listingData['longitude'] = coordinates.longitude;
      }

      // Insert the listing into the database
      final response = await _supabase
          .from('Listings')
          .insert(listingData)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create listing: $e');
    }
  }

  /// Complete function to upload images and create listing
  static Future<Map<String, dynamic>> uploadListingWithImages({
    required String propertyType,
    required double price,
    required String location,
    required List<String> imagePaths,
    required List<String> amenities,
    String? title,
    String? description,
    String? area,
    String? address,
    LatLng? coordinates,
  }) async {
    try {
      // Step 1: Upload all images to Supabase Storage
      final uploadedPhotoUrls = await uploadImagesToSupabase(imagePaths);

      // Step 2: Create the listing in the database
      final listing = await createListing(
        propertyType: propertyType,
        price: price,
        location: location,
        photos: uploadedPhotoUrls,
        amenities: amenities,
        title: title,
        description: description,
        area: area,
        address: address,
        coordinates: coordinates,
      );

      return listing;
    } catch (e) {
      throw Exception('Failed to upload listing with images: $e');
    }
  }

  /// Get all listings from the database
  static Future<List<Map<String, dynamic>>> getAllListings() async {
    try {
      final response = await _supabase
          .from('Listings')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch listings: $e');
    }
  }

  /// Get a single listing by ID
  static Future<Map<String, dynamic>> getListingById(String id) async {
    try {
      final response =
          await _supabase.from('Listings').select().eq('id', id).single();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch listing: $e');
    }
  }

  /// Update an existing listing
  static Future<Map<String, dynamic>> updateListing({
    required String id,
    String? propertyType,
    double? price,
    String? location,
    List<String>? photos,
    List<String>? amenities,
    String? title,
    String? description,
    String? area,
    String? address,
    LatLng? coordinates,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (propertyType != null) updateData['property_type'] = propertyType;
      if (price != null) updateData['price'] = price;
      if (location != null) updateData['location'] = location;
      if (photos != null) updateData['photos'] = photos;
      if (amenities != null) updateData['amenities'] = amenities;
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (area != null) updateData['area'] = area;
      if (address != null) updateData['address'] = address;
      if (coordinates != null) {
        updateData['latitude'] = coordinates.latitude;
        updateData['longitude'] = coordinates.longitude;
      }

      final response = await _supabase
          .from('Listings')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to update listing: $e');
    }
  }

  /// Delete a listing and its associated images
  static Future<void> deleteListing(String id) async {
    try {
      // First, get the listing to find the image URLs
      final listing = await getListingById(id);
      final photos = List<String>.from(listing['photos'] ?? []);

      // Delete images from storage
      for (String photoUrl in photos) {
        try {
          // Extract filename from URL
          final uri = Uri.parse(photoUrl);
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            final fileName = pathSegments.last;
            await _supabase.storage.from('propertyphotos').remove([fileName]);
          }
        } catch (e) {
          // Continue even if image deletion fails
          print('Failed to delete image: $e');
        }
      }

      // Delete the listing from database
      await _supabase.from('Listings').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete listing: $e');
    }
  }

  /// Search listings by various criteria
  static Future<List<Map<String, dynamic>>> searchListings({
    String? propertyType,
    double? minPrice,
    double? maxPrice,
    String? location,
    List<String>? amenities,
  }) async {
    try {
      var query = _supabase.from('Listings').select();

      if (propertyType != null) {
        query = query.eq('property_type', propertyType);
      }

      if (minPrice != null) {
        query = query.gte('price', minPrice);
      }

      if (maxPrice != null) {
        query = query.lte('price', maxPrice);
      }

      if (location != null) {
        query = query.ilike('location', '%$location%');
      }

      final response = await query.order('created_at', ascending: false);
      List<Map<String, dynamic>> listings =
          List<Map<String, dynamic>>.from(response);

      // Filter by amenities if provided
      if (amenities != null && amenities.isNotEmpty) {
        listings = listings.where((listing) {
          final listingAmenities =
              List<String>.from(listing['amenities'] ?? []);
          return amenities
              .every((amenity) => listingAmenities.contains(amenity));
        }).toList();
      }

      return listings;
    } catch (e) {
      throw Exception('Failed to search listings: $e');
    }
  }

  // Add a property to user's favorites
  static Future<void> addFavorite(String userId, String listingId) async {
    try {
      await _supabase.from('Favorites').insert({
        'user_id': userId,
        'listing_id': listingId,
      });
    } catch (e) {
      throw Exception('Failed to add favorite: $e');
    }
  }

  // Remove a property from user's favorites
  static Future<void> removeFavorite(String userId, String listingId) async {
    try {
      final response = await _supabase
          .from('Favorites')
          .delete()
          .eq('user_id', userId)
          .eq('listing_id', listingId);
      // Optionally check if response is empty or not
      if (response == null || (response is List && response.isEmpty)) {
        throw Exception('Favorite not found or already removed.');
      }
    } catch (e) {
      throw Exception('Failed to remove favorite: $e');
    }
  }

  // Fetch all favorite listings for a user (returns full listing data)
  static Future<List<Map<String, dynamic>>> getFavoriteListings(
      String userId) async {
    try {
      // Step 1: Get all favorite listing IDs for the user
      final favResponse = await _supabase
          .from('Favorites')
          .select('listing_id')
          .eq('user_id', userId);
      final favoriteIds = (favResponse as List)
          .map((fav) => fav['listing_id'].toString())
          .toList();
      if (favoriteIds.isEmpty) return [];
      // Step 2: Fetch all listings with those IDs
      final listingsResponse =
          await _supabase.from('Listings').select().inFilter('id', favoriteIds);
      return List<Map<String, dynamic>>.from(listingsResponse);
    } catch (e) {
      throw Exception('Failed to fetch favorite listings: $e');
    }
  }
}

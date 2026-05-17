import { appEnv } from '../../config/env.js';
import { AppError } from '../../utils/app-error.js';

export interface NearbyPlacesInput {
  lat: number;
  lng: number;
  type: string;
  keyword?: string;
}

export class PlacesService {
  async fetchNearbyPlaces(input: NearbyPlacesInput) {
    if (!appEnv.GOOGLE_PLACES_API_KEY) {
      throw new AppError(
        500,
        'GOOGLE_PLACES_API_KEY_MISSING',
        'GOOGLE_PLACES_API_KEY is missing in backend .env',
      );
    }

    const url = new URL(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
    );

    url.searchParams.set('location', `${input.lat},${input.lng}`);
    url.searchParams.set('radius', '2500');
    url.searchParams.set('type', input.type);
    url.searchParams.set('language', 'ko');
    url.searchParams.set('key', appEnv.GOOGLE_PLACES_API_KEY);

    if (input.keyword) {
      url.searchParams.set('keyword', input.keyword);
    }

    const response = await fetch(url);

    if (!response.ok) {
      throw new AppError(
        response.status,
        'GOOGLE_PLACES_HTTP_ERROR',
        'Failed to fetch Google Places API',
      );
    }

    const json = await response.json();

    if (json.status && json.status !== 'OK' && json.status !== 'ZERO_RESULTS') {
      throw new AppError(
        400,
        'GOOGLE_PLACES_API_ERROR',
        json.error_message ?? json.status,
        json,
      );
    }

    const results = Array.isArray(json.results)
      ? json.results.slice(0, 5)
      : [];

    return results.map((place: any) => {
      const photoReference = place.photos?.[0]?.photo_reference;

      return {
        id: place.place_id ?? '',
        name: place.name ?? '',
        lat: place.geometry?.location?.lat ?? 0,
        lng: place.geometry?.location?.lng ?? 0,
        rating: place.rating ?? 0,
        reviewCount: place.user_ratings_total ?? 0,
        priceLevel: place.price_level ?? null,
        address: place.vicinity ?? '',
        photoUrl: photoReference
          ? `/api/v1/places/photo?photoReference=${encodeURIComponent(photoReference)}`
          : null,
      };
    });
  }

  buildPhotoUrl(photoReference: string) {
    const url = new URL(
      'https://maps.googleapis.com/maps/api/place/photo',
    );

    url.searchParams.set('maxwidth', '800');
    url.searchParams.set('photo_reference', photoReference);
    url.searchParams.set('key', appEnv.GOOGLE_PLACES_API_KEY);

    return url.toString();
  }
}
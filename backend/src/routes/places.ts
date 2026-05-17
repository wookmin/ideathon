import { Router } from 'express';
import { z } from 'zod';

import { PlacesService } from '../modules/places/places-service.js';
import { asyncHandler } from '../utils/async-handler.js';

const nearbyPlacesSchema = z.object({
  lat: z.coerce.number(),
  lng: z.coerce.number(),
  type: z.string().min(1),
  keyword: z.string().optional(),
});

const photoSchema = z.object({
  photoReference: z.string().min(1),
});

export function createPlacesRouter(placesService: PlacesService) {
  const router = Router();

  router.get(
    '/nearby',
    asyncHandler(async (req, res) => {
      const query = nearbyPlacesSchema.parse(req.query);

      const places = await placesService.fetchNearbyPlaces({
        lat: query.lat,
        lng: query.lng,
        type: query.type,
        keyword: query.keyword,
      });

      res.json({ places });
    }),
  );

  router.get(
    '/photo',
    asyncHandler(async (req, res) => {
      const query = photoSchema.parse(req.query);
      const photoUrl = placesService.buildPhotoUrl(query.photoReference);

      res.redirect(photoUrl);
    }),
  );

  return router;
}
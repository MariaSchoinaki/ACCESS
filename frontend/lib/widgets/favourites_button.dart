import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/favourites_bloc/favourites_cubit.dart';
import '../models/mapbox_feature.dart';

class FavoriteStarButton extends StatelessWidget {
  final MapboxFeature feature;

  const FavoriteStarButton({
    super.key,
    required this.feature
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, state) {
        final isFavorite = context.read<FavoritesCubit>().isFavorite(feature.id);
        return IconButton(
          icon: Icon(
            isFavorite ? Icons.star : Icons.star_border,
            color: isFavorite ? Colors.yellow[700] : Colors.grey,
          ),
          onPressed: () {
            context.read<FavoritesCubit>().toggleFavorite(
              feature: feature
            );
          },
        );
      },
    );
  }
}

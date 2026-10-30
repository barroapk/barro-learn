import 'package:flutter/material.dart';

import '../theme.dart';

/// Un métier du catalogue. Seuls les métiers « disponibles » ont déjà un parcours.
class Metier {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool available;

  const Metier(this.id, this.title, this.subtitle, this.icon, {this.available = false});
}

class MetierCategory {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color; // couleur de l'icône et des accents
  final Color tint; // fond doux
  final List<Metier> metiers;

  const MetierCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tint,
    required this.metiers,
  });

  int get openCount => metiers.where((m) => m.available).length;
}

const metierCategories = [
  MetierCategory(
    title: 'Agriculture & élevage',
    subtitle: 'Produire, élever, nourrir',
    icon: Icons.eco_outlined,
    color: BarroColors.greenText,
    tint: BarroColors.greenSoft,
    metiers: [
      Metier('poulet-chair', 'Élevage de poulets de chair', '15 leçons · 6 semaines', Icons.egg_outlined, available: true),
      Metier('maraichage', 'Maraîchage', 'Jardin potager et légumes', Icons.grass),
      Metier('pondeuses', 'Poules pondeuses', 'Produire et vendre des œufs', Icons.egg_alt_outlined),
      Metier('embouche', 'Embouche ovine', 'Engraisser des moutons', Icons.pets_outlined),
      Metier('pisciculture', 'Pisciculture', 'Élever des poissons', Icons.set_meal_outlined),
    ],
  ),
  MetierCategory(
    title: 'Réparation & technique',
    subtitle: 'Réparer, installer, entretenir',
    icon: Icons.build_outlined,
    color: BarroColors.blue,
    tint: BarroColors.blueSoft,
    metiers: [
      Metier('telephones', 'Réparation de téléphones', 'Écrans, batteries, connecteurs', Icons.phone_android),
      Metier('solaire', 'Installation solaire simple', 'Panneau, batterie, éclairage', Icons.solar_power_outlined),
      Metier('electricite', 'Électricité de bâtiment', 'Prises, câbles, sécurité', Icons.electrical_services),
      Metier('moto', 'Mécanique moto', 'Entretien et petites pannes', Icons.two_wheeler),
    ],
  ),
  MetierCategory(
    title: 'Commerce & numérique',
    subtitle: 'Vendre, gérer, créer en ligne',
    icon: Icons.storefront_outlined,
    color: BarroColors.orangeText,
    tint: BarroColors.orangeSoft,
    metiers: [
      Metier('vente-ligne', 'Vendre sur WhatsApp et Facebook', 'Catalogue, clients, livraison', Icons.chat_outlined),
      Metier('boutique', 'Gérer une petite boutique', 'Stock, caisse, bénéfice', Icons.point_of_sale),
      Metier('app-android', 'Créer une app Android', 'Depuis son téléphone', Icons.code),
    ],
  ),
  MetierCategory(
    title: 'Transformation & artisanat',
    subtitle: 'Transformer et fabriquer',
    icon: Icons.handyman_outlined,
    color: BarroColors.violet,
    tint: BarroColors.violetSoft,
    metiers: [
      Metier('savon', 'Fabrication de savon', 'Savon artisanal et liquide', Icons.soap_outlined),
      Metier('jus', 'Jus et sirops locaux', 'Bissap, gingembre, tamarin', Icons.local_drink_outlined),
      Metier('karite', 'Beurre de karité', 'Transformer et conditionner', Icons.spa_outlined),
      Metier('couture', 'Couture', 'Prendre les mesures, coudre', Icons.content_cut),
    ],
  ),
];

int get metierCount => metierCategories.fold(0, (sum, c) => sum + c.metiers.length);

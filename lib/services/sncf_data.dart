import 'dart:convert';
import 'package:loosted/models/found_object.dart';
import 'package:http/http.dart' as http;
import 'package:loosted/services/database_helper.dart';

class SncfData {
  final String apiUrl =
      'https://data.sncf.com/api/explore/v2.1/catalog/datasets/objets-trouves-restitution/records';
  final String lastFounded = "?order_by=date%20DESC&limit=100";

  Future<List<FoundObject>> fetchFoundObjects() async {
    final response = await http.get(Uri.parse(apiUrl + lastFounded));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['results'];
      return data.map((item) => FoundObject.fromJson(item)).toList();
    }
    throw Exception('Failed to load found objects');
  }

  // Rechercher des objets trouvés selon les filtres
  Future<List<FoundObject>> searchFoundObjects({
    String? stationName, // Filtrer par nom de la gare
    String? objectType, // Filtrer par type d'objet
    DateTime? dateMin, // Filtrer par date minimale
    DateTime? dateMax, // Filtrer par date maximale
    bool onlyNew = false, // Si true, les objets déjà vus sont exclus
  }) async {
    String whereClause = '';

    // Ajoute le filtre par gare
    if (stationName != null && stationName.isNotEmpty) {
      whereClause +=
          'gc_obo_gare_origine_r_name%20%3D%20%22${Uri.encodeComponent(stationName)}%22';
    }

    //Ajoute le filtre Type
    if (objectType != null && objectType.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += '%20AND%20';
      whereClause +=
          'gc_obo_type_c%20%3D%20%22${Uri.encodeComponent(objectType)}%22';
    }

    // Ajoute le filtre par date min
    if (dateMin != null) {
      final dateMinStr =
          '${dateMin.day.toString().padLeft(2, '0')}/${dateMin.month.toString().padLeft(2, '0')}/${dateMin.year}';
      if (whereClause.isNotEmpty) whereClause += '%20AND%20';
      whereClause += 'date%20%3E%3D%20%22$dateMinStr%22';
    }

    // Ajoute le filtre par date max
    if (dateMax != null) {
      final dateMaxStr =
          '${dateMax.day.toString().padLeft(2, '0')}/${dateMax.month.toString().padLeft(2, '0')}/${dateMax.year}';
      if (whereClause.isNotEmpty) whereClause += '%20AND%20';
      whereClause += 'date%20%3C%3D%20%22$dateMaxStr%22';
    }
    // Construction de l'URL finale avec le tri par date décroissante et la limite
    String finalUrl =
        '$apiUrl?where=$whereClause&order_by=date%20DESC&limit=100';

    // Effectue la requête HTTP
    final response = await http.get(Uri.parse(finalUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['results'];
      List<FoundObject> foundObjects =
          data.map((item) => FoundObject.fromJson(item)).toList();

      // Si onlyNew est activé, filtrer les objets déjà vus
      if (onlyNew) {
        // Récupérer les objets déjà vus depuis la base de données
        final dbHelper = DatabaseHelper();
        List<String> viewedObjectIds = await dbHelper.getViewedObjectIds();

        // Filtrer les objets dont l'ID est déjà vu
        foundObjects = foundObjects.where((object) {
          return !viewedObjectIds.contains(object.getUniqueId());
        }).toList();
      }

      return foundObjects;
    } else {
      throw Exception('Erreur lors de la récupération des objets trouvés');
    }
  }

  List<String> objectTypes = [
    'Bagagerie: sacs, valises, cartables',
    'Appareils électroniques, informatiques, appareils photo',
    'Vêtements, chaussures',
    'Porte-monnaie / portefeuille, argent, titres',
    'Pièces d\'identités et papiers personnels',
    'Optique',
    'Clés, porte-clés, badge magnétique',
    'Divers',
    'Livres, articles de papeterie',
    'Vélos, trottinettes, accessoires 2 roues',
    'Articles de sport, loisirs, camping',
    'Articles d\'enfants, de puériculture',
    'Parapluies',
    'Bijoux, montres',
    'Articles médicaux',
    'Instruments de musique',
  ];

  List<String> trainStations = [
    'Paris Gare de Lyon',
    'Paris Montparnasse',
    'Paris Gare du Nord',
    'Paris Saint-Lazare',
    'Strasbourg',
    'Lille Europe',
    'Bordeaux Saint-Jean',
    'Rennes',
    'Marseille Saint-Charles',
    'Nantes',
    'Paris Est',
    'Lyon Perrache',
    'Toulouse Matabiau',
    'Lyon Part Dieu',
    'Brest',
    'Nice',
    'Montpellier Saint-Roch',
    'Mulhouse',
    'Paris Austerlitz',
    'Tours',
    'Orléans',
    'Hendaye',
    'La Rochelle',
    'Nancy',
    'Quimper',
    'Le Mans',
    'Grenoble',
    'Caen',
    'Dijon',
    'Metz Ville',
    'Perpignan',
    'Rouen Rive Droite',
    'Poitiers',
    'Aéroport Charles de Gaulle 2 TGV',
    'Angers Saint-Laud',
    'Clermont-Ferrand',
    'Cherbourg',
    'Avignon TGV',
    'Annecy',
    'Le Havre',
    'Chambéry - Challes-les-Eaux',
    'Paris Bercy',
    'Amiens',
    'Valence',
    'Tarbes',
    'Toulon',
    'Saint-Étienne Châteaucreux',
    'Marne-la-Vallée Chessy',
    'Montpellier Sud de France',
    'Tourcoing',
    'Brive-la-Gaillarde',
    'Bourges',
    'Limoges Bénédictins',
    'Besançon Viotte',
    'Nîmes',
    'Aix-en-Provence TGV',
    'Saint-Nazaire',
    'Agen',
    'Narbonne',
    'Dunkerque',
    'Chartres',
    'Périgueux',
    'Reims',
    'Colmar',
    'Nevers',
    'Vierzon',
    'Cannes',
    'Boulogne Ville',
    'Le Croisic',
    'Mantes-la-Jolie',
    'Massy TGV',
    'Béziers',
    'Valence TGV Rhône-Alpes Sud',
    'Saint-Pierre-des-Corps',
    'Bourg-Saint-Maurice',
    'Avignon Centre',
    'Les Aubrais',
    'Pau',
    'Laroche - Migennes',
    'Granville',
    'Creil',
    'Bayonne',
    'Dax',
    'Niort',
    'Angoulême',
    'Bellegarde',
    'Compiègne',
    'Bourg-en-Bresse',
    'Haguenau',
    'Arras',
    'Sélestat',
    'Lorient Bretagne Sud',
    'Saintes',
    'Roanne',
    'Douai',
    'Saint-Brieuc',
    'Calais Ville',
    'Saint-Malo',
    'Épinal',
    'Montauban Ville Bourbon',
  ];
}

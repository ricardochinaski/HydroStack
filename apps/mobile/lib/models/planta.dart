class PlantaParams {
  final String ph;
  final String ec;
  final String temp;
  final String luz;
  final String humedad;
  final String riego;

  const PlantaParams({
    required this.ph,
    required this.ec,
    required this.temp,
    required this.luz,
    required this.humedad,
    required this.riego,
  });
}

class Nutrientes {
  final int n;
  final int p;
  final int k;
  final int ca;
  final int mg;

  const Nutrientes({
    required this.n,
    required this.p,
    required this.k,
    required this.ca,
    required this.mg,
  });
}

class TimelineItem {
  final String week;
  final String title;
  final String desc;

  const TimelineItem({
    required this.week,
    required this.title,
    required this.desc,
  });
}

class AlertaPlanta {
  final String type;
  final String icon;
  final String title;
  final String desc;

  const AlertaPlanta({
    required this.type,
    required this.icon,
    required this.title,
    required this.desc,
  });
}

class SensorPlanta {
  final String name;
  final String desc;
  final String range;

  const SensorPlanta({
    required this.name,
    required this.desc,
    required this.range,
  });
}

class Planta {
  final String id;
  final String name;
  final String latin;
  final String emoji;
  final String category;
  final String difficulty;
  final String diffLabel;
  final String description;
  final String harvestDays;
  final PlantaParams params;
  final Nutrientes nutrients;
  final List<TimelineItem> timeline;
  final List<AlertaPlanta> alerts;
  final List<SensorPlanta> sensors;
  final String tip;

  const Planta({
    required this.id,
    required this.name,
    required this.latin,
    required this.emoji,
    required this.category,
    required this.difficulty,
    required this.diffLabel,
    required this.description,
    required this.harvestDays,
    required this.params,
    required this.nutrients,
    required this.timeline,
    required this.alerts,
    required this.sensors,
    required this.tip,
  });
}

// VMO Aero — site-aligned content catalog (offline-first).

import 'package:flutter/material.dart';

class TriviaItem {
  const TriviaItem(this.label, this.body);
  final String label;
  final String body;
}

class QuizQuestion {
  const QuizQuestion(this.prompt, this.options, this.correctIndex);
  final String prompt;
  final List<String> options;
  final int correctIndex;
}

class QuizPack {
  const QuizPack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.questions,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<QuizQuestion> questions;
}

class CabinScramble {
  const CabinScramble(this.word, this.hint);
  final String word;
  final String hint;
}

class CabinPoll {
  const CabinPoll(this.question, this.options);
  final String question;
  final List<String> options;
}

class BadgeItem {
  const BadgeItem(this.id, this.title, this.subtitle);
  final String id;
  final String title;
  final String subtitle;
}

class ServiceItem {
  const ServiceItem({
    required this.title,
    required this.tagline,
    required this.body,
    required this.color,
    required this.icon,
    this.bullets = const [],
    this.steps = const [],
  });

  final String title;
  final String tagline;
  final String body;
  final Color color;
  final IconData icon;
  final List<String> bullets;
  final List<(String, String)> steps;
}

class WhyItem {
  const WhyItem(this.title, this.body);
  final String title;
  final String body;
}

class BriefItem {
  const BriefItem({
    required this.title,
    required this.excerpt,
    required this.date,
    required this.readMins,
    required this.category,
  });

  final String title;
  final String excerpt;
  final String date;
  final int readMins;
  final String category;
}

class TeamMember {
  const TeamMember(this.name, this.role);
  final String name;
  final String role;
}

class ClientStory {
  const ClientStory(this.name, this.title, this.quote);
  final String name;
  final String title;
  final String quote;
}

class FaqItem {
  const FaqItem(this.question, this.answer);
  final String question;
  final String answer;
}

class CateringMenuItem {
  const CateringMenuItem({
    required this.id,
    required this.name,
    required this.category,
    this.imageAsset,
  });

  final String id;
  final String name;
  final String category;

  /// Null when no photo is available — UI shows a blank tile.
  final String? imageAsset;
}

abstract final class AppContent {
  static const companyName = 'VMO Aero';
  static const tagline =
      'Bespoke Aircraft Acquisition and Asset Management Company';
  static const serviceStrip =
      'Acquisition · Management · Charter · Operations · Maintenance · Protocol · Advisory';

  static const profile =
      'VMO Aero is a bespoke aircraft acquisition and asset management '
      'company, providing structured, system-driven solutions aligned with '
      'global aviation standards. We ensure every aircraft under our '
      'oversight is managed with clarity, excellence, and a focus on '
      'long-term performance.';

  static const mission =
      'One coordinated partner from sourcing and purchase through operations '
      'and maintenance — acquire the aircraft, operate with authority.';

  static const vision =
      'To be the private aviation office for Nigeria and West Africa — '
      'accountable for acquisition, management, charter, and flight support '
      'under one roof.';

  static const history =
      'Built around how principals actually fly: home bases, preferred '
      'routing, family schedules, and corporate demands. VMO Aero designs '
      'programmes that scale with usage — not generic templates.';

  static const leadership =
      'Lagos head office, airport operations, and UK representation — '
      'one team for charter and ownership.';

  static const whyChoose = <WhyItem>[
    WhyItem(
      'Mission-led sourcing',
      'Every search starts with how you fly: passengers, routes, home base, '
          'and budget — not whatever happens to be listed online.',
    ),
    WhyItem(
      'Due diligence you can act on',
      'Records review, inspection coordination, valuation, and lien checks '
          'presented as a decision memo — not an unreadable stack of PDFs.',
    ),
    WhyItem(
      'Nigerian pathway expertise',
      'Importation, NCAA compliance, escrow, and registry coordination '
          'managed with teams who understand the local operating environment.',
    ),
    WhyItem(
      'Straight into management',
      'Acquisition does not end at delivery. We can transition the aircraft '
          'directly into VMO management with crew, maintenance, and operations.',
    ),
  ];

  static const services = <ServiceItem>[
    ServiceItem(
      title: 'Aircraft Acquisition & Brokerage',
      tagline: 'From intention to ownership with clarity.',
      color: Color(0xFF1F2D90),
      icon: Icons.travel_explore_outlined,
      body:
          'VMO Aero is a bespoke aircraft acquisition and asset management '
          'company. Acquisition is treated as a structured mandate — IATA-certified '
          'expertise in aircraft acquisition and financing, supported by partnerships '
          'with global FBOs and MRO organisations, so sourcing, inspection, and '
          'closing stay aligned with global aviation standards.\n\n'
          'We provide a clear framework from first brief through registry. The '
          'aircraft is sourced against how it will actually fly, verified before '
          'commitment, and — where required — handed straight into Total Aircraft '
          'Management so ownership does not stall between delivery and operations.',
      bullets: [
        'Mission-led sourcing across owner-direct, broker, and OEM pipelines',
        'Technical, legal, and commercial due diligence before commitment',
        'Financing structure, escrow, importation, and registry coordination',
        'Optional handover into VMO STRATA™, STEWARD™, or SELECT™ management',
      ],
      steps: [
        ('Define the brief', 'Mission profile, cabin needs, budget, registry, and timeline — not whatever happens to be listed.'),
        ('Source beyond listings', 'Broker networks, owner-direct, and OEM pipelines across West Africa, Europe, and the Middle East.'),
        ('Verify before you commit', 'Technical records, inspection, valuation, title and lien search — presented as a decision memo.'),
        ('Close with structure', 'Purchase agreements, escrow, NCAA pathway, importation, and registry.'),
        ('Hand over to operations', 'Acceptance, insurance, operator setup, and optional VMO management so standards do not slip at delivery.'),
      ],
    ),
    ServiceItem(
      title: 'Total Aircraft Management',
      tagline: 'Your private aviation office.',
      color: Color(0xFF34C759),
      icon: Icons.manage_accounts_outlined,
      body:
          'Aircraft ownership goes beyond having the asset. It requires continuous '
          'coordination across operations, maintenance, regulatory compliance, and '
          'cost control.\n\n'
          'Total Aircraft Management provides the structure required to maintain '
          'alignment and control. VMO Aero integrates operations, maintenance, '
          'compliance, utilization, and financial oversight into a single '
          'coordinated system that ensures clear visibility, excellent execution, '
          'and well-informed decision making across the aircraft lifecycle.\n\n'
          'These elements are interdependent. Flight activity drives maintenance '
          'requirements. Maintenance determines availability. Compliance depends '
          'on accurate records and timely execution. Costs are shaped by how well '
          'these areas are managed together. When managed in isolation, gaps lead '
          'to delays, reactive maintenance, compliance exposure, and avoidable '
          'cost inefficiencies.\n\n'
          'Engagements are structured as VMO STRATA™, VMO STEWARD™, or VMO SELECT™ '
          '— full financial structure, full professional management, or focused '
          'support across selected functions.',
      bullets: [
        'Operational planning, dispatch coordination, and real-time flight monitoring',
        'Crew planning, scheduling, and end-to-end trip coordination',
        'Maintenance planning, technical coordination, and airworthiness oversight',
        'Regulatory compliance, documentation control, and authority liaison',
        'Utilization planning and charter coordination, where applicable',
        'Financial oversight, structured reporting, and performance visibility',
      ],
      steps: [
        ('Tailor the mandate', 'Home bases, routing, family and corporate schedules — STRATA™, STEWARD™, or SELECT™.'),
        ('Operate with discipline', 'Planning, permits, handling, and on-the-day coordination under one office.'),
        ('Protect the asset', 'Maintenance, airworthiness, records, and transparent owner reporting.'),
        ('Optimise commercially', 'Charter placement and empty-leg marketing when you are not flying.'),
      ],
    ),
    ServiceItem(
      title: 'Private Jet & Helicopter Charter',
      tagline: 'On-demand private flights, refined.',
      color: Color(0xFFFF9F0A),
      icon: Icons.flight_takeoff_outlined,
      body:
          'Charter sits inside the same coordinated system as management. '
          'Utilization planning and charter coordination are handled where '
          'applicable, so the aircraft is positioned in active local and '
          'international markets without fragmenting operations, maintenance, '
          'or compliance.\n\n'
          'Missions are matched to jets and helicopters with punctuality, cabin '
          'comfort, and ground coordination from a single accountable partner — '
          'the same office that already sees crew, airworthiness, and cost.',
      bullets: [
        'Jet and helicopter matching to the mission',
        'Utilization planning and charter coordination',
        'Ground handling, permits, and cabin preferences',
        'Commercial placement when the aircraft is not flying privately',
      ],
    ),
    ServiceItem(
      title: 'Flight and Ground Operations Support',
      tagline: 'Permits, fuel, weather, and handling.',
      color: Color(0xFF32ADE6),
      icon: Icons.support_agent_outlined,
      body:
          'Operational planning, dispatch coordination, and real-time flight '
          'monitoring sit at the centre of Total Aircraft Management. A dedicated '
          'desk keeps the mission moving from planning to landing — crew planning, '
          'scheduling, and end-to-end trip coordination under one office.\n\n'
          'Permits, fuel, weather, ramp coordination, and operational control on '
          'the day are executed with the same discipline applied to managed '
          'assets, so gaps between flight activity and ground support do not '
          'become delays or compliance exposure.',
      bullets: [
        'Operational planning, dispatch, and real-time flight monitoring',
        'Crew planning, scheduling, and end-to-end trip coordination',
        'Permits, clearances, fuel, weather, and NOTAMs',
        'Ground handling and ramp coordination',
      ],
    ),
    ServiceItem(
      title: 'Aircraft Maintenance Oversight',
      tagline: 'Airworthiness you can report on.',
      color: Color(0xFFFF3B30),
      icon: Icons.build_outlined,
      body:
          'Maintenance planning, technical coordination, and airworthiness '
          'oversight are not a separate vendor stream. Flight activity drives '
          'maintenance requirements; maintenance determines availability. VMO Aero '
          'coordinates scheduled and unscheduled technical work with MRO partners '
          'so the aircraft stays mission-ready.\n\n'
          'Where the mandate includes financial structure, a Maintenance Reserve '
          'is held for scheduled and unscheduled technical requirements — reducing '
          'exposure to unplanned costs while keeping records accurate and '
          'authority-ready.',
      bullets: [
        'Maintenance planning, technical coordination, and airworthiness oversight',
        'Scheduled inspection planning and defect / AOG coordination',
        'AD / SB tracking and documentation control',
        'Owner-facing status reports — not an unread stack of work orders',
      ],
    ),
    ServiceItem(
      title: 'Executive Protocol (VIP Support)',
      tagline: 'Discreet arrivals, seamless ground.',
      color: Color(0xFFAF52DE),
      icon: Icons.workspace_premium_outlined,
      body:
          'Protocol is part of end-to-end trip coordination — not an add-on '
          'handled by a third party at the last hour. Principals, families, and '
          'visiting delegations are received with FBO coordination, security '
          'liaison, and motorcade timing aligned to the same dispatch picture '
          'as the aircraft.\n\n'
          'Cabin preferences, catering, and ground arrangements are executed '
          'with consistency, responsiveness, and attention to detail — the same '
          'standard VMO Aero applies across operations and client experience.',
      bullets: [
        'VIP arrival and departure choreography',
        'FBO, lounge, and passenger handling',
        'Security and motorcade liaison',
        'Cabin, catering, and ground preferences',
      ],
    ),
    ServiceItem(
      title: 'Aviation Regulatory Advisory',
      tagline: 'Clarity before you fly or register.',
      color: Color(0xFF00C7BE),
      icon: Icons.gavel_outlined,
      body:
          'VMO Aero operates under ISO 9001:2015 and ISO 29001:2020 certified '
          'quality systems, with active membership of NBAA and AfBAA, and is '
          'licensed by the Nigerian Civil Aviation Authority (NCAA).\n\n'
          'Regulatory compliance, documentation control, and authority liaison '
          'are built into every mandate. Advisory covers NCAA pathways, ownership '
          'structures, importation, and operating approvals — so decisions are '
          'informed before you fly or register, not discovered at the wrong moment.',
      bullets: [
        'NCAA, registry, and authority liaison',
        'Documentation control and compliance records',
        'Ownership, operating, and importation structures',
        'ISO 9001:2015 / ISO 29001:2020 quality systems',
      ],
    ),
  ];

  static const briefs = <BriefItem>[
    BriefItem(
      title: 'What Is Aircraft Remarketing and When Does It Make Sense?',
      excerpt:
          'Aircraft remarketing is the process of strategically preparing and '
          'marketing an aircraft for sale to maximise its value and minimise '
          'time on market.',
      date: 'June 9, 2026',
      readMins: 7,
      category: 'Middle of Funnel',
    ),
    BriefItem(
      title: 'Understanding Aircraft Liens and Title Searches in the Acquisition Process',
      excerpt:
          'One of the most important but least glamorous aspects of aircraft '
          'acquisition is legal due diligence — particularly lien and title search.',
      date: 'June 6, 2026',
      readMins: 7,
      category: 'Middle of Funnel',
    ),
    BriefItem(
      title: 'Aircraft Positioning Flights: What They Are and How to Manage the Cost',
      excerpt:
          'Positioning flights (ferry / empty legs) reposition an aircraft '
          'without revenue passengers for the next mission.',
      date: 'June 3, 2026',
      readMins: 7,
      category: 'Middle of Funnel',
    ),
  ];

  static const team = <TeamMember>[
    TeamMember('Leadership Team', 'Acquisition, management & operations'),
    TeamMember('Flight Operations', 'Planning, permits & on-the-day coordination'),
    TeamMember('Ground Desk', 'Lagos head office & airport operations'),
    TeamMember('UK Representation', 'Belfast desk for international coordination'),
  ];

  static const stories = <ClientStory>[
    ClientStory(
      'Chinedu Okafor',
      'Founder, Lagos-based investment firm',
      'VMO Aero has revolutionized the way I conduct business travel. The '
          'attention to detail, punctuality, and luxurious experience have '
          'made them my exclusive choice for private aviation.',
    ),
    ClientStory(
      'Amina Bello',
      'Family Office Principal',
      'Ownership finally feels accountable. One partner from acquisition '
          'through day-to-day operations — without chasing vendors.',
    ),
    ClientStory(
      'Tomiwa Adeyemi',
      'Group CEO, West African conglomerate',
      'Charter and management under one roof means fewer gaps and clearer '
          'standards every time we fly.',
    ),
  ];

  static const faqs = <FaqItem>[
    FaqItem(
      'What services does VMO Aero provide?',
      'We oversee every detail of private jet ownership and charter — from '
          'flight and ground operations to maintenance oversight, crew '
          'coordination, and regulatory compliance. Our role is to act as '
          'your private aviation office.',
    ),
    FaqItem(
      'Do you offer custom-tailored aircraft management solutions?',
      'Yes. Each management mandate is tailored to your missions: home '
          'bases, preferred routing, family schedules, and corporate demands.',
    ),
    FaqItem(
      'How much does it cost to charter an aircraft with VMO Aero?',
      'Charter pricing depends on aircraft type, routing, positioning, and '
          'ground requirements. Speak with our team for a mission-specific quotation.',
    ),
    FaqItem(
      'How do I know if VMO Aero\'s management package is right for me?',
      'If you want a single accountable partner for operations, maintenance, '
          'compliance, and reporting — instead of a patchwork of vendors — '
          'management is designed for you.',
    ),
    FaqItem(
      'How do I book a charter flight with VMO Aero?',
      'Contact our Ground Desk with your route, dates, and passenger details. '
          'We match aircraft, coordinate handling, and confirm your mission.',
    ),
  ];

  static const contactEmail = 'info@vmoaeros.com';
  static const contactPhone = '+234 906 469 8508 · 070-00-VMOAERO';
  static const headOffice =
      '127, Oduduwa Crescent, GRA Ikeja, Lagos State, Nigeria.';
  static const airportOffice =
      'Dominion Hanger, Murtala Mohammed International Airport, Ikeja, Lagos State.';
  static const ukOffice =
      '201 Albert Bridge Road, Belfast BT5 4PU, Northern Ireland.';
  static const charterDesk = 'Ground Desk — charter & ownership';
  static const contactAddress =
      'Head office: 127, Oduduwa Crescent, GRA Ikeja, Lagos.';
  static const contactHours = 'Available for charter & consultation enquiries';

  static const certificationNote =
      'VMO Aero certification and compliance documentation available on request '
      'through our Ground Desk and principal portal.';

  static const trivia = <TriviaItem>[
    TriviaItem(
      'Acquisition',
      'Title searches and lien checks protect buyers long after delivery day.',
    ),
    TriviaItem(
      'Operations',
      'Positioning flights (empty legs) move an aircraft to where the next mission starts.',
    ),
    TriviaItem(
      'Nigeria',
      'NCAA compliance, importation, and registry coordination are central to owning locally.',
    ),
    TriviaItem(
      'Charter',
      'A charter quote usually bundles aircraft, crew, fuel planning, and handling — not just seat price.',
    ),
    TriviaItem(
      'Cabin',
      'Cabin altitude on many business jets sits well below airliner levels, which is why you feel fresher.',
    ),
    TriviaItem(
      'Maintenance',
      'Scheduled inspections and AD compliance keep an aircraft airworthy between missions.',
    ),
    TriviaItem(
      'Crew',
      'Duty-time limits and rest rules protect decision quality as much as schedule convenience.',
    ),
    TriviaItem(
      'Weather',
      'Alternate airports and fuel reserves are planned before wheels-up, not after a surprise hold.',
    ),
    TriviaItem(
      'Ownership',
      'Direct operating cost includes fuel, maintenance reserves, crew, and hangar — not just the purchase price.',
    ),
    TriviaItem(
      'Flight support',
      'Permits, slots, and ground handling turn a route idea into an executable itinerary.',
    ),
  ];

  static const quizPacks = <QuizPack>[
    QuizPack(
      id: 'captain_brief',
      title: 'Captain Brief',
      subtitle: 'Ownership, charter, and VMO fundamentals',
      questions: [
        QuizQuestion(
          'What does VMO Aero act as for owners and charter clients?',
          [
            'A travel agency only',
            'Your private aviation office',
            'An aircraft manufacturer',
          ],
          1,
        ),
        QuizQuestion(
          'When should title and lien diligence happen?',
          ['After delivery', 'Before funds move', 'Only at resale'],
          1,
        ),
        QuizQuestion(
          'Which service covers crew, maintenance, and NCAA compliance?',
          ['Private Jet & Helicopter Charter', 'Total Aircraft Management', 'Cabin catering'],
          1,
        ),
        QuizQuestion(
          'What is an empty leg?',
          [
            'A cancelled flight',
            'A positioning flight with no passengers',
            'A ferry with cargo only',
          ],
          1,
        ),
        QuizQuestion(
          'Which Nigerian authority is central to local aircraft registry work?',
          ['NCAA', 'FAA only', 'ICAO alone'],
          0,
        ),
        QuizQuestion(
          'A strong ownership plan should include which of these early?',
          [
            'Mission profile and operating budget',
            'Cabin paint colour only',
            'Inflight movie list',
          ],
          0,
        ),
      ],
    ),
    QuizPack(
      id: 'sky_smart',
      title: 'Sky Smart',
      subtitle: 'Quick aviation knowledge for cabin guests',
      questions: [
        QuizQuestion(
          'Why do business jets often feel less tiring than airlines?',
          [
            'Louder cabins',
            'Typically lower cabin altitude',
            'No seatbelts',
          ],
          1,
        ),
        QuizQuestion(
          'What does ATC primarily manage?',
          [
            'Inflight catering menus',
            'Safe separation and traffic flow',
            'Aircraft paint schemes',
          ],
          1,
        ),
        QuizQuestion(
          'Fuel planning should account for which reserve concept?',
          [
            'Only exact destination fuel',
            'Destination plus contingency and alternates',
            'Fuel for taxi only',
          ],
          1,
        ),
        QuizQuestion(
          'A NOTAM is best described as:',
          [
            'A passenger Wi-Fi password',
            'A notice to air missions about operational changes',
            'A catering invoice',
          ],
          1,
        ),
        QuizQuestion(
          'Which is a common reason to choose charter over ownership?',
          [
            'Guaranteed daily utilisation forever',
            'Flexible access without full ownership cost',
            'Unlimited free upgrades to airliners',
          ],
          1,
        ),
      ],
    ),
    QuizPack(
      id: 'ops_deck',
      title: 'Ops Deck',
      subtitle: 'Flight support and management scenarios',
      questions: [
        QuizQuestion(
          'Ground handling typically covers:',
          [
            'Aircraft purchase contracts',
            'Ramp, passenger, and turnaround support',
            'Airframe design',
          ],
          1,
        ),
        QuizQuestion(
          'Crew duty limits exist mainly to:',
          [
            'Reduce catering waste',
            'Protect safety and decision quality',
            'Speed up boarding',
          ],
          1,
        ),
        QuizQuestion(
          'An alternate airport is planned so that:',
          [
            'You always land early',
            'You have a viable option if destination closes',
            'Fuel burn is ignored',
          ],
          1,
        ),
        QuizQuestion(
          'Total aircraft management is closest to:',
          [
            'Owning the jet with zero support',
            'Running the aircraft like a professional office',
            'Selling tickets by the seat only',
          ],
          1,
        ),
      ],
    ),
  ];

  /// Legacy single-list accessor used by older UI paths.
  static List<QuizQuestion> get quiz => quizPacks.first.questions;

  static const scrambles = <CabinScramble>[
    CabinScramble('RUNWAY', 'Where takeoff begins'),
    CabinScramble('HANGAR', 'Where the jet rests'),
    CabinScramble('COCKPIT', 'Flight deck home'),
    CabinScramble('TURBULENCE', 'Bumps in the air'),
    CabinScramble('ALTITUDE', 'How high you fly'),
    CabinScramble('CHARTER', 'On-demand private flight'),
    CabinScramble('NIGERIA', 'Home base market'),
    CabinScramble('THROTTLE', 'Power lever'),
  ];

  static const cabinPolls = <CabinPoll>[
    CabinPoll(
      'Preferred cabin mood for a long sector?',
      ['Quiet focus', 'Soft music', 'Conversation'],
    ),
    CabinPoll(
      'First thing you want after wheels-up?',
      ['Water & fruit', 'Hot meal', 'Wi-Fi & work'],
    ),
    CabinPoll(
      'Ideal seating for a Lagos–London hop?',
      ['Club four', 'Forward lounge', 'Private suite'],
    ),
    CabinPoll(
      'Best in-flight entertainment?',
      ['Cabin games', 'Aviation quiz', 'Quiet window time'],
    ),
  ];

  static const cabinTips = <String>[
    'Hydrate early — cabin air is dry even on short hops.',
    'Ask crew about meal timing before you settle into deep work.',
    'Keep passport and permits accessible until doors close.',
    'Soft layers beat one heavy jacket when cabin temperature shifts.',
    'A short stretch before descent helps you walk off feeling sharp.',
  ];

  static const badges = <BadgeItem>[
    BadgeItem('first_quiz', 'Cabin Scholar', 'Complete your first aviation quiz'),
    BadgeItem('perfect', 'Perfect Brief', 'Score full marks on a quiz pack'),
    BadgeItem('sky_scholar', 'Sky Scholar', 'Score at least 70% on a quiz'),
    BadgeItem('trivia', 'Briefing Room', 'Read three trivia cards'),
    BadgeItem('sky_ace', 'Sky Ace', 'Score 100+ in Sky Strike'),
    BadgeItem('smooth_air', 'Smooth Air', 'Reach 80 in Jet Dodge'),
    BadgeItem('memory_pilot', 'Memory Pilot', 'Clear a Runway Memory board'),
    BadgeItem('cloud_rider', 'Cloud Rider', 'Clear 8 gates in Cloud Hop'),
    BadgeItem('tower_copy', 'Tower Copy', 'Reach sequence 5 in Tower Call'),
    BadgeItem('wordsmith', 'Wordsmith', 'Solve a Cabin Scramble'),
    BadgeItem('cabin_voice', 'Cabin Voice', 'Cast a vote in a cabin poll'),
  ];
}

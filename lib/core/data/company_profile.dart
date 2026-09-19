class ProfileBlock {
  const ProfileBlock({
    required this.heading,
    required this.body,
    this.imageAsset,
    this.bullets = const [],
  });

  final String heading;
  final String body;
  final String? imageAsset;
  final List<String> bullets;
}

class ProfileModel {
  const ProfileModel({
    required this.name,
    required this.mark,
    required this.body,
    required this.imageAsset,
  });

  final String name;
  final String mark;
  final String body;
  final String imageAsset;
}

class ProfileAdvantage {
  const ProfileAdvantage({
    required this.title,
    required this.body,
    required this.iconName,
  });

  final String title;
  final String body;
  final String iconName;
}

abstract final class CompanyProfile {
  static const dir = 'assets/images/profile';
  static const coverAsset = '$dir/profile_cover.png';

  static const tagline =
      'Bespoke Aircraft Acquisition and Asset Management Company.';
  static const website = 'www.vmoaeros.com';
  static const handle = '@vmo_aero';

  static const credentials = <String>[
    'ISO 9001:2015',
    'ISO 29001:2020',
    'IATA-certified expertise',
    'NBAA',
    'AfBAA',
    'NCAA licensed',
  ];

  static const intro = ProfileBlock(
    heading: 'Who we are',
    imageAsset: '$dir/profile_cover.png',
    body:
        'VMO Aero is a bespoke aircraft acquisition and asset management '
        'company, providing structured, system-driven solutions aligned with '
        'global aviation standards. We ensure every aircraft under our '
        'oversight is managed with clarity, excellence, and a focus on '
        'long-term performance.',
  );

  static const expertise = ProfileBlock(
    heading: 'Expertise and partnerships',
    imageAsset: '$dir/profile_expertise.png',
    body:
        'Our team brings International Air Transport Association (IATA)-certified '
        'expertise in aircraft acquisition, financing, and management, supported '
        'by partnerships with global Fixed Base Operators (FBOs) and '
        'Maintenance, Repair, and Overhaul (MRO) organisations, enabling '
        'coordinated and dependable support across key locations.\n\n'
        'We provide a clear and structured framework that ensures aircraft are '
        'not only operational, but properly managed and consistently aligned '
        'with their intended purpose.',
  );

  static const credentialsBody = ProfileBlock(
    heading: 'Quality systems',
    body:
        'We operate under International Organization for Standardization (ISO) '
        '9001:2015 and ISO 29001:2020 certified quality systems, with active '
        'membership of the National Business Aviation Association (NBAA) and '
        'the African Business Aviation Association (AfBAA), and are licensed '
        'by the Nigerian Civil Aviation Authority (NCAA).\n\n'
        'These values shape how we think, how we operate, and how we deliver.',
  );

  static const ownership = ProfileBlock(
    heading: 'Ownership with structure',
    body:
        'Aircraft ownership goes beyond having the asset. It requires '
        'continuous coordination across operations, maintenance, regulatory '
        'compliance, and cost control.',
  );

  static const management = ProfileBlock(
    heading: 'Total Aircraft Management',
    imageAsset: '$dir/profile_management.png',
    body:
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
        'cost inefficiencies.',
    bullets: [
      'Operational planning, dispatch coordination, and real-time flight monitoring',
      'Crew planning, scheduling, and end-to-end trip coordination',
      'Maintenance planning, technical coordination, and airworthiness oversight',
      'Regulatory compliance, documentation control, and authority liaison',
      'Utilization planning and charter coordination, where applicable',
      'Financial oversight, structured reporting, and performance visibility',
    ],
  );

  static const managementClose =
      'With centralized coordination and continuous oversight, aircraft are '
      'not only operational, but consistently managed, compliant, and aligned '
      'with long-term ownership objectives.';

  static const acquisition = ProfileBlock(
    heading: 'Aircraft acquisition',
    imageAsset: '$dir/profile_expertise.png',
    body:
        'Aircraft acquisition is a structured mandate — not a listing search. '
        'VMO Aero brings IATA-certified expertise in aircraft acquisition and '
        'financing, supported by partnerships with global FBOs and MRO '
        'organisations, so every search, inspection, and closing is coordinated '
        'against the same operating standard that will later manage the asset.\n\n'
        'We provide a clear framework from first brief through registry: the '
        'aircraft is sourced against how it will actually fly, verified before '
        'commitment, and — where required — handed straight into Total Aircraft '
        'Management so ownership does not stall between delivery and operations.',
    bullets: [
      'Mission-led sourcing across owner-direct, broker, and OEM pipelines',
      'Technical, legal, and commercial due diligence before commitment',
      'Financing structure, escrow, importation, and registry coordination',
      'Optional handover into VMO STRATA™, STEWARD™, or SELECT™ management',
    ],
  );

  static const acquisitionModels = <ProfileModel>[
    ProfileModel(
      name: 'End-to-end acquisition',
      mark: '',
      imageAsset: '$dir/profile_cover.png',
      body:
          'For clients who want one accountable partner from intention to '
          'ownership. VMO Aero defines the mission brief, sources beyond public '
          'listings, coordinates inspection and valuation, structures the '
          'purchase, and completes importation and registry.\n\n'
          'This model is designed so acquisition does not end at delivery. The '
          'same office can transition the aircraft into Total Aircraft '
          'Management — crew, maintenance, compliance, and financial oversight '
          'already aligned to the platform you have just acquired.',
    ),
    ProfileModel(
      name: 'Brokerage and sales support',
      mark: '',
      imageAsset: '$dir/profile_expertise.png',
      body:
          'For buyers and sellers who need the aircraft positioned in active '
          'local and international markets. VMO Aero works owner-direct and '
          'through trusted broker networks so the right counterparties are '
          'reached, and the transaction is coordinated with the same discipline '
          'applied to managed assets.\n\n'
          'Market access is paired with structured execution: records, '
          'inspection windows, and commercial terms are handled so the aircraft '
          'moves cleanly — whether you are acquiring or disposing of the asset.',
    ),
    ProfileModel(
      name: 'Financing and pathway advisory',
      mark: '',
      imageAsset: '$dir/profile_visibility.png',
      body:
          'For clients who retain their own search or operator, but need '
          'IATA-certified expertise on financing, NCAA pathways, importation, '
          'and closing structure.\n\n'
          'This model does not replace full acquisition or management. It '
          'provides targeted support where exposure is highest — title and lien '
          'search, escrow, registry, and a decision-ready view of cost and '
          'compliance — so ownership is entered with clarity rather than '
          'unresolved risk.',
    ),
  ];

  static const models = <ProfileModel>[
    ProfileModel(
      name: 'VMO STRATA',
      mark: '™',
      imageAsset: '$dir/profile_strata.png',
      body:
          'The VMO STRATA™ Model is a structured management framework designed '
          'for clients who require a defined financial structure over the '
          'operational lifecycle of the aircraft.\n\n'
          'Under this model, VMO Aero manages the aircraft across all '
          'operational and technical areas, while establishing a structured '
          'financial plan based on the assessed value of the aircraft. A defined '
          'return framework is developed, allowing the value of the aircraft to '
          'be recovered over an agreed operational period through structured '
          'monthly returns.\n\n'
          'To support operational stability and reduce exposure to unplanned '
          'costs, dedicated reserves are maintained: a Maintenance Reserve for '
          'scheduled and unscheduled technical requirements, and an Operations '
          'Reserve for recurring operational costs and contingencies.\n\n'
          'This model combines full operational management with financial '
          'structure, ensuring that the aircraft is managed within a structured '
          'environment that supports consistent performance, cost predictability, '
          'and long-term value alignment.',
    ),
    ProfileModel(
      name: 'VMO STEWARD',
      mark: '™',
      imageAsset: '$dir/profile_steward.png',
      body:
          'The VMO STEWARD™ Model is designed for clients who require full '
          'professional management of their aircraft while retaining direct '
          'financial responsibility for operational and maintenance costs.\n\n'
          'Under this model, VMO Aero manages the aircraft end-to-end, ensuring '
          'that operations, maintenance, compliance, and coordination are '
          'executed with discipline and consistency. All operational and '
          'technical decisions are centrally managed, while costs are funded '
          'directly by the client as they arise.\n\n'
          'This model does not include structured financial returns, reserve '
          'retention, or asset value recovery frameworks. Instead, it focuses '
          'on maintaining high standards of execution, clear oversight, and '
          'reliable day-to-day management.',
    ),
    ProfileModel(
      name: 'VMO SELECT',
      mark: '™',
      imageAsset: '$dir/profile_select.png',
      body:
          'The VMO SELECT™ Model is designed for clients who require focused '
          'support across specific areas of aircraft management, rather than '
          'full end-to-end oversight.\n\n'
          'Under this model, VMO Aero provides management across selected '
          'functions such as operations, commercial coordination, maintenance '
          'oversight, or regulatory support, depending on the client’s '
          'requirements. Each engagement is structured to integrate seamlessly '
          'with the client’s existing setup, while maintaining the same level of '
          'discipline, coordination, and execution.\n\n'
          'This model allows clients to retain control of certain aspects of the '
          'aircraft while relying on VMO Aero for targeted expertise and '
          'structured delivery in defined areas.',
    ),
  ];

  static const visibility = ProfileBlock(
    heading: 'Live visibility',
    imageAsset: '$dir/profile_visibility.png',
    body:
        'VMO Aero maintains clear and consistent visibility across all aircraft '
        'activities, ensuring that clients remain fully informed at all times.\n\n'
        'Operational and financial information is tracked continuously and '
        'presented through a structured live reporting system, allowing for '
        'clear understanding of aircraft performance, cost exposure, and '
        'overall activity.',
  );

  static const advantageIntro =
      'We have access to active local and international markets, enabling us '
      'to position aircraft effectively and unlock real commercial opportunities.';

  static const advantages = <ProfileAdvantage>[
    ProfileAdvantage(
      title: 'Market Access',
      iconName: 'public',
      body:
          'We have access to active local and international markets, enabling '
          'us to position aircraft effectively and unlock real commercial '
          'opportunities.',
    ),
    ProfileAdvantage(
      title: 'Local and International Partnerships',
      iconName: 'handshake',
      body:
          'We work with trusted partners across key markets, ensuring reliable '
          'support, seamless coordination, and access to the right resources '
          'when needed.',
    ),
    ProfileAdvantage(
      title: 'Integrated Management',
      iconName: 'hub',
      body:
          'We bring operations, maintenance, compliance, and financial oversight '
          'into one aligned system, ensuring clarity and consistency across all '
          'activities.',
    ),
    ProfileAdvantage(
      title: 'Execution and Service Excellence',
      iconName: 'verified',
      body:
          'We deliver with consistency, responsiveness, and attention to detail, '
          'ensuring a high standard across operations and client experience.',
    ),
    ProfileAdvantage(
      title: 'Value and Sustainability',
      iconName: 'eco',
      body:
          'We focus on long-term value through proper management, compliant '
          'operations, and a sustainable approach to performance and asset use.',
    ),
    ProfileAdvantage(
      title: 'Full Visibility and Transparency',
      iconName: 'visibility',
      body:
          'We provide clear visibility across operations and finances, enabling '
          'informed decisions, accountability, and sustained confidence.',
    ),
  ];
}

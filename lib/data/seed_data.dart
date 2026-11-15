import 'package:flutter/material.dart';

import '../models/models.dart';

/// SAMPLE CONTENT. Dates are generated relative to "now" so the app always
/// looks alive. Replace this with real data (Firestore, an API, a CMS...).
/// Contact e-mails below are placeholders, not official addresses.
class SeedData {
  static DateTime _at(int dayOffset, int hour, [int minute = 0]) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day + dayOffset, hour, minute);
  }

  static DateTime _ago({int days = 0, int hours = 0}) =>
      DateTime.now().subtract(Duration(days: days, hours: hours));

  // ───────────── Announcements ─────────────
  static final List<Announcement> announcements = [
    Announcement(
      id: 'n1',
      title: 'Mid-term exam timetable is now published',
      body:
          "The timetable for the mid-term examination period is available on the student portal.\n\nPlease check your schedule carefully, note your room assignments, and arrive at least 15 minutes before each exam. Student cards are mandatory.\n\nIf you spot a clash between two exams, contact the Registrar's Office within 48 hours so that a solution can be arranged.",
      author: 'Registrar\'s Office',
      category: AnnCategory.academic,
      date: _ago(hours: 3),
      pinned: true,
      highPriority: true,
      authorRole: 'professor',
    ),
    Announcement(
      id: 'n2',
      title: 'Campus Wi-Fi maintenance tonight, 23:00 to 01:00',
      body:
          "The IT department will upgrade the campus network tonight between 23:00 and 01:00.\n\nWi-Fi may be unavailable or unstable during this window, including in the residences. Please save your work and plan online tasks accordingly.\n\nFor urgent issues, contact IT Support.",
      author: 'IT Support',
      category: AnnCategory.urgent,
      date: _ago(hours: 6),
    ),
    Announcement(
      id: 'n3',
      title: 'Career Fair: submit your CV before Friday',
      body:
          "Our annual Career Fair brings together companies and recruiters looking for interns and graduates.\n\nTo take part, upload your CV through the Careers Office form before Friday. Selected students will receive their interview slots by email.\n\nTip: bring printed copies and dress professionally.",
      author: 'Careers Office',
      category: AnnCategory.careers,
      date: _ago(days: 1),
    ),
    Announcement(
      id: 'n4',
      title: 'Library opens late during exam weeks',
      body:
          "To support your revision, the library will extend its opening hours during the exam period.\n\nSilent study rooms can be booked at the front desk. Please keep food and drinks out of the study areas.",
      author: 'University Library',
      category: AnnCategory.administration,
      date: _ago(days: 1, hours: 5),
    ),
    Announcement(
      id: 'n5',
      title: 'Student Council elections: candidacies are open',
      body:
          "Want to represent your classmates? Candidacies for the Student Council are now open.\n\nSubmit your short programme and a photo to Student Affairs. A campaign week will follow, with open debates on campus.",
      author: 'Student Affairs',
      category: AnnCategory.campusLife,
      date: _ago(days: 2),
    ),
    Announcement(
      id: 'n6',
      title: 'Erasmus+ mobility: information session',
      body:
          "Thinking about studying abroad next year? Join the information session to learn about partner universities, eligibility, grants and the application calendar.\n\nBring your questions: former exchange students will share their experience.",
      author: 'International Office',
      category: AnnCategory.academic,
      date: _ago(days: 3),
    ),
    Announcement(
      id: 'n7',
      title: 'Summer internship offers are online',
      body:
          "New internship offers for next summer have been added to the careers platform.\n\nFilter by field, location and duration. Remember that your internship agreement must be signed by the university before your start date.",
      author: 'Careers Office',
      category: AnnCategory.careers,
      date: _ago(days: 4),
    ),
    Announcement(
      id: 'n8',
      title: 'New shuttle schedule from next week',
      body:
          "The shuttle between the city centre and campus will run on an updated schedule starting next week, with extra departures in the early morning and late afternoon.\n\nThe full timetable is displayed at the main entrance.",
      author: 'Campus Services',
      category: AnnCategory.administration,
      date: _ago(days: 5),
    ),
    Announcement(
      id: 'n9',
      title: 'Cafeteria: new menu and student prices',
      body:
          "The cafeteria introduces a rotating weekly menu with vegetarian options every day and a new student combo.\n\nShare your feedback at the cashier or through your student representatives.",
      author: 'Campus Services',
      category: AnnCategory.campusLife,
      date: _ago(days: 6),
    ),
    Announcement(
      id: 'n10',
      title: 'Civil Engineering: site visit registration is open',
      body:
          "Second-year and third-year Civil Engineering students can now register for next week's construction site visit.\n\nPlaces are limited and safety equipment is mandatory. Confirm your attendance with your programme coordinator.",
      author: 'Civil Engineering Department',
      category: AnnCategory.academic,
      date: _ago(hours: 9),
      department: 'Civil Engineering',
      authorRole: 'professor',
    ),
    Announcement(
      id: 'n11',
      title: 'AI Lab seminar: machine learning in healthcare',
      body:
          "The Computer Science & AI department invites its students to a seminar on applied machine learning in healthcare.\n\nA short demo session follows the talk. Bring questions about projects and internships.",
      author: 'Computer Science & AI Department',
      category: AnnCategory.academic,
      date: _ago(days: 1, hours: 2),
      department: 'Computer Science & AI',
      authorRole: 'professor',
    ),
  ];

  // ───────────── Events ─────────────
  static final List<CampusEvent> events = [
    CampusEvent(
      id: 'e1',
      title: 'Flutter for Beginners: build your first app',
      description:
          "A hands-on evening workshop where you build and run a small mobile app from zero. Bring your laptop with Flutter installed, or come early and we will help you set it up.\n\nNo prior mobile experience required.",
      location: 'Lab 2, Engineering Building',
      organizer: 'DevHub Club',
      category: EventCategory.workshop,
      start: _at(0, 17),
      end: _at(0, 19, 30),
      clubId: 'devhub',
      baseGoing: 42,
    ),
    CampusEvent(
      id: 'e2',
      title: 'Open Mic Night',
      description:
          "Music, poetry, stand-up: the stage is yours. Sign up at the door or just come to cheer on your friends. Snacks and drinks available.",
      location: 'Student Lounge',
      organizer: 'Harmony Music Club',
      category: EventCategory.cultural,
      start: _at(1, 19),
      end: _at(1, 21, 30),
      clubId: 'harmony',
      baseGoing: 86,
    ),
    CampusEvent(
      id: 'e3',
      title: 'Guest lecture: AI and Society',
      description:
          "A researcher in artificial intelligence discusses how AI is reshaping work, education and creativity, followed by an open Q&A session with students.",
      location: 'Main Amphitheatre',
      organizer: 'Academic Affairs',
      category: EventCategory.academic,
      start: _at(2, 11),
      end: _at(2, 12, 30),
      baseGoing: 154,
    ),
    CampusEvent(
      id: 'e4',
      title: 'Inter-faculty Football Tournament',
      description:
          "Group stage day of the annual inter-faculty tournament. Cheer for your faculty, wear your colours, and bring water.",
      location: 'Sports Field',
      organizer: 'Eagles Sports Club',
      category: EventCategory.sport,
      start: _at(3, 15),
      end: _at(3, 18),
      clubId: 'eagles',
      baseGoing: 120,
    ),
    CampusEvent(
      id: 'e5',
      title: 'Career Fair',
      description:
          "Meet recruiters, discover internships and get feedback on your CV. Registration through the Careers Office is required. Bring printed CVs.",
      location: 'Main Hall',
      organizer: 'Careers Office',
      category: EventCategory.career,
      start: _at(4, 9, 30),
      end: _at(4, 16),
      baseGoing: 310,
    ),
    CampusEvent(
      id: 'e6',
      title: 'Medina Photo Walk',
      description:
          "Explore the old city with your camera. We will share composition tips, golden-hour spots and finish with a mini photo exhibition vote. Phones are welcome too.",
      location: 'Meeting point: main gate',
      organizer: 'Lens Photography Club',
      category: EventCategory.cultural,
      start: _at(5, 16),
      end: _at(5, 19),
      clubId: 'lens',
      baseGoing: 37,
    ),
    CampusEvent(
      id: 'e7',
      title: 'Parliamentary Debate Night',
      description:
          "Two teams, one motion, a panel of judges. Come to compete or to watch and learn how structured debate works.",
      location: 'Room B204',
      organizer: 'Agora Debate Club',
      category: EventCategory.academic,
      start: _at(6, 18),
      end: _at(6, 20),
      clubId: 'agora',
      baseGoing: 28,
    ),
    CampusEvent(
      id: 'e8',
      title: 'Robotics Demo Day',
      description:
          "See the club's line-following and robotic arm projects in action, and learn how to join the next competition team.",
      location: 'Innovation Lab',
      organizer: 'RoboFez Club',
      category: EventCategory.workshop,
      start: _at(7, 14),
      end: _at(7, 16, 30),
      clubId: 'robofez',
      baseGoing: 51,
    ),
    CampusEvent(
      id: 'e9',
      title: 'Erasmus+ Information Session',
      description:
          "Everything you need to know about studying abroad: partner universities, grants, deadlines and testimonies from returning students.",
      location: 'Room A105',
      organizer: 'International Office',
      category: EventCategory.academic,
      start: _at(8, 12, 30),
      end: _at(8, 14),
      baseGoing: 73,
    ),
    CampusEvent(
      id: 'e10',
      title: 'Blood Donation Drive',
      description:
          "Give a little time, save lives. A medical team will be on campus all day. Please eat well and drink water before donating, and bring your ID.",
      location: 'Health Center',
      organizer: 'Community Action Club',
      category: EventCategory.cultural,
      start: _at(9, 9),
      end: _at(9, 15),
      clubId: 'impact',
      baseGoing: 64,
    ),
    CampusEvent(
      id: 'e11',
      title: 'Startup Pitch Evening',
      description:
          "Student teams pitch their ideas in three minutes to a panel of entrepreneurs. Come for the ideas, stay for the networking.",
      location: 'Innovation Lab',
      organizer: 'Founders Club',
      category: EventCategory.career,
      start: _at(11, 18),
      end: _at(11, 20, 30),
      clubId: 'founders',
      baseGoing: 59,
    ),
    CampusEvent(
      id: 'e12',
      title: 'Charity Run 5K',
      description:
          "A friendly 5 km run around the campus loop. All levels welcome, walking is fine too. All registration fees go to a local education charity.",
      location: 'Sports Field',
      organizer: 'Eagles Sports Club',
      category: EventCategory.sport,
      start: _at(12, 10),
      end: _at(12, 12),
      clubId: 'eagles',
      baseGoing: 97,
    ),
  ];

  // ───────────── Clubs ─────────────
  static final List<Club> clubs = [
    Club(
      id: 'devhub',
      name: 'DevHub',
      tagline: 'Code, build, ship together.',
      description:
          "DevHub is the home of student developers. We run weekly coding sessions, hackathons, and workshops on web, mobile and AI. Beginners are very welcome: you learn by building real projects with people who care.",
      category: ClubCategory.tech,
      members: 214,
      color: const Color(0xFF7C5CFF),
      iconKey: 'code',
      president: 'Club President',
      email: 'devhub@ueuromed.org',
      updates: [
        ClubUpdate(
            text: 'Flutter for Beginners workshop is open for registration. Limited seats!',
            date: _ago(hours: 5)),
        ClubUpdate(
            text: 'Our spring hackathon team won second place. Congratulations to everyone!',
            date: _ago(days: 6)),
        ClubUpdate(
            text: 'New weekly session: algorithms and interview prep, every Thursday.',
            date: _ago(days: 12)),
      ],
    ),
    Club(
      id: 'robofez',
      name: 'RoboFez',
      tagline: 'Robots, sensors and big ideas.',
      description:
          "We design, build and program robots for competitions and for fun. From microcontrollers to autonomous navigation, learn hardware and software side by side.",
      category: ClubCategory.science,
      members: 96,
      color: const Color(0xFF22D3EE),
      iconKey: 'robot',
      president: 'Club President',
      email: 'robofez@ueuromed.org',
      updates: [
        ClubUpdate(
            text: 'Demo Day is coming. Come see our robotic arm in action.',
            date: _ago(days: 1)),
        ClubUpdate(
            text: 'Recruiting: electronics and 3D-printing volunteers.',
            date: _ago(days: 9)),
      ],
    ),
    Club(
      id: 'harmony',
      name: 'Harmony',
      tagline: 'Where campus finds its sound.',
      description:
          "Harmony brings musicians and music lovers together: jam sessions, concerts, open mics and collaborations. Singers, instrumentalists and producers all have a place here.",
      category: ClubCategory.arts,
      members: 133,
      color: const Color(0xFFFF4D8D),
      iconKey: 'music',
      president: 'Club President',
      email: 'harmony@ueuromed.org',
      updates: [
        ClubUpdate(
            text: 'Open Mic Night tomorrow at the Student Lounge. Sign-ups are open.',
            date: _ago(hours: 20)),
        ClubUpdate(
            text: 'Instruments available for loan to members. Ask at our next meeting.',
            date: _ago(days: 8)),
      ],
    ),
    Club(
      id: 'agora',
      name: 'Agora Debate',
      tagline: 'Think sharp. Speak bold.',
      description:
          "Agora trains students in public speaking, argumentation and critical thinking through weekly practice debates and inter-university competitions.",
      category: ClubCategory.social,
      members: 71,
      color: const Color(0xFFFFB84D),
      iconKey: 'forum',
      president: 'Club President',
      email: 'agora@ueuromed.org',
      updates: [
        ClubUpdate(
            text: 'Parliamentary Debate Night this week. Come to compete or watch.',
            date: _ago(days: 2)),
      ],
    ),
    Club(
      id: 'lens',
      name: 'Lens',
      tagline: 'See the world differently.',
      description:
          "A club for photographers of every level. Photo walks, editing workshops and exhibitions. A phone camera is enough to start.",
      category: ClubCategory.arts,
      members: 88,
      color: const Color(0xFFD946EF),
      iconKey: 'camera',
      president: 'Club President',
      email: 'lens@ueuromed.org',
      updates: [
        ClubUpdate(
            text: 'Medina Photo Walk announced. Golden hour, great light.',
            date: _ago(days: 3)),
        ClubUpdate(
            text: 'Photos of the month are now on display near the library.',
            date: _ago(days: 14)),
      ],
    ),
    Club(
      id: 'eagles',
      name: 'Eagles Sports',
      tagline: 'Play hard, play together.',
      description:
          "Football, basketball, running and more. We organise training sessions, friendly matches and the inter-faculty tournaments. Everyone can play.",
      category: ClubCategory.sport,
      members: 178,
      color: const Color(0xFF34D399),
      iconKey: 'soccer',
      president: 'Club President',
      email: 'eagles@ueuromed.org',
      updates: [
        ClubUpdate(
            text: 'Tournament group stage starts soon. Check your faculty team list.',
            date: _ago(days: 1, hours: 4)),
        ClubUpdate(
            text: 'Charity Run 5K registrations are open.',
            date: _ago(days: 4)),
      ],
    ),
    Club(
      id: 'founders',
      name: 'Founders',
      tagline: 'Turn ideas into companies.',
      description:
          "A community for future entrepreneurs: pitch practice, mentoring from founders, startup visits and a yearly pitch evening.",
      category: ClubCategory.social,
      members: 102,
      color: const Color(0xFFFF7A59),
      iconKey: 'rocket',
      president: 'Club President',
      email: 'founders@ueuromed.org',
      updates: [
        ClubUpdate(
            text: 'Pitch Evening: apply with your idea before the deadline.',
            date: _ago(days: 5)),
      ],
    ),
    Club(
      id: 'impact',
      name: 'Community Action',
      tagline: 'Small actions, real impact.',
      description:
          "Volunteering, awareness campaigns and solidarity projects. From blood drives to tutoring and clean-up days, we make campus and city a better place.",
      category: ClubCategory.social,
      members: 145,
      color: const Color(0xFF3B82F6),
      iconKey: 'volunteer',
      president: 'Club President',
      email: 'impact@ueuromed.org',
      updates: [
        ClubUpdate(
            text: 'Blood Donation Drive on campus. Volunteers needed at the welcome desk.',
            date: _ago(days: 2, hours: 3)),
      ],
    ),
  ];

  // ───────────── Campus ─────────────
  static const Set<int> _weekdays = {1, 2, 3, 4, 5};
  static const Set<int> _allWeek = {1, 2, 3, 4, 5, 6, 7};

  static final List<Facility> facilities = [
    Facility(
      id: 'library',
      name: 'Library',
      description:
          'Books, study rooms, printing and research databases. Silent study floors on the upper levels.',
      iconKey: 'library',
      location: 'Central Building, 1st floor',
      openMinute: 8 * 60,
      closeMinute: 20 * 60,
      days: {1, 2, 3, 4, 5, 6},
      contact: 'library@ueuromed.org',
    ),
    Facility(
      id: 'cafeteria',
      name: 'Cafeteria',
      description:
          'Hot meals, sandwiches, vegetarian options and a student combo menu.',
      iconKey: 'restaurant',
      location: 'Student Hall',
      openMinute: 7 * 60 + 30,
      closeMinute: 18 * 60,
      days: _weekdays,
    ),
    Facility(
      id: 'registrar',
      name: 'Registrar',
      description:
          'Certificates, enrolment, transcripts, exam timetables and academic records.',
      iconKey: 'badge',
      location: 'Administration, ground floor',
      openMinute: 9 * 60,
      closeMinute: 16 * 60,
      days: _weekdays,
      contact: 'registrar@ueuromed.org',
    ),
    Facility(
      id: 'it',
      name: 'IT Support',
      description:
          'Wi-Fi access, student accounts, password resets and lab equipment help.',
      iconKey: 'support',
      location: 'Engineering Building, room 12',
      openMinute: 8 * 60 + 30,
      closeMinute: 17 * 60,
      days: _weekdays,
      contact: 'it-support@ueuromed.org',
    ),
    Facility(
      id: 'health',
      name: 'Health Center',
      description:
          'First aid, nurse consultations and health advice for students.',
      iconKey: 'health',
      location: 'Near the sports field',
      openMinute: 9 * 60,
      closeMinute: 17 * 60,
      days: _weekdays,
    ),
    Facility(
      id: 'gym',
      name: 'Gym',
      description:
          'Fitness room, indoor courts and equipment loans. Bring your student card.',
      iconKey: 'gym',
      location: 'Sports Complex',
      openMinute: 8 * 60,
      closeMinute: 21 * 60,
      days: _allWeek,
    ),
    Facility(
      id: 'student_affairs',
      name: 'Student Affairs',
      description:
          'Clubs, events, student life, scholarships and student council support.',
      iconKey: 'groups',
      location: 'Administration, 1st floor',
      openMinute: 9 * 60,
      closeMinute: 17 * 60,
      days: _weekdays,
      contact: 'studentaffairs@ueuromed.org',
    ),
    Facility(
      id: 'security',
      name: 'Security Desk',
      description:
          'Lost and found, access issues and campus safety. Staffed around the clock.',
      iconKey: 'shield',
      location: 'Main gate',
      openMinute: 0,
      closeMinute: 1440,
      days: _allWeek,
    ),
  ];

  static final List<CampusContact> contacts = [
    CampusContact(
      name: 'General contact',
      role: 'University information desk',
      email: 'contact@ueuromed.org',
      icon: Icons.mail_rounded,
    ),
    CampusContact(
      name: 'Student Affairs',
      role: 'Clubs, events, student life',
      email: 'studentaffairs@ueuromed.org',
      icon: Icons.groups_rounded,
    ),
    CampusContact(
      name: 'Registrar',
      role: 'Certificates and records',
      email: 'registrar@ueuromed.org',
      icon: Icons.badge_rounded,
    ),
    CampusContact(
      name: 'IT Support',
      role: 'Accounts, Wi-Fi, equipment',
      email: 'it-support@ueuromed.org',
      icon: Icons.support_agent_rounded,
    ),
    CampusContact(
      name: 'Careers Office',
      role: 'Internships and recruiters',
      email: 'careers@ueuromed.org',
      icon: Icons.work_rounded,
    ),
  ];
}

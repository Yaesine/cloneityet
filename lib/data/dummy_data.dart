import '../models/user_model.dart';
import '../models/match_model.dart';

class DummyData {
  static List<User> getDummyUsers() {
    return [
      User(
        id: 'user_1',
        name: 'Sophie',
        age: 28,
        bio: 'Travel enthusiast and coffee addict. Love hiking and exploring new places.',
        imageUrls: ['https://i.pravatar.cc/300?img=1', 'https://i.pravatar.cc/300?img=5'],
        interests: ['Travel', 'Coffee', 'Hiking', 'Photography'],
        location: 'New York, NY',
      ),
      User(
        id: 'user_2',
        name: 'James',
        age: 32,
        bio: 'Software developer by day, chef by night. Looking for someone to share meals with.',
        imageUrls: ['https://i.pravatar.cc/300?img=3', 'https://i.pravatar.cc/300?img=7'],
        interests: ['Coding', 'Cooking', 'Movies', 'Running'],
        location: 'Brooklyn, NY',
      ),
      User(
        id: 'user_3',
        name: 'Emma',
        age: 26,
        bio: 'Art lover and yoga instructor. Passionate about sustainability and mindful living.',
        imageUrls: ['https://i.pravatar.cc/300?img=9', 'https://i.pravatar.cc/300?img=11'],
        interests: ['Yoga', 'Art', 'Sustainability', 'Reading'],
        location: 'Queens, NY',
      ),
      User(
        id: 'user_4',
        name: 'Michael',
        age: 30,
        bio: 'Music producer and drummer. Love concerts and discovering new bands.',
        imageUrls: ['https://i.pravatar.cc/300?img=13', 'https://i.pravatar.cc/300?img=15'],
        interests: ['Music', 'Concerts', 'Drums', 'Traveling'],
        location: 'Manhattan, NY',
      ),
      User(
        id: 'user_5',
        name: 'Olivia',
        age: 27,
        bio: 'PhD student in marine biology. Beach lover and scuba diving enthusiast.',
        imageUrls: ['https://i.pravatar.cc/300?img=17', 'https://i.pravatar.cc/300?img=19'],
        interests: ['Scuba Diving', 'Ocean', 'Science', 'Books'],
        location: 'Jersey City, NJ',
      ),
    ];
  }

  static User getCurrentUser() {
    return User(
      id: 'user_123',
      name: 'Alex',
      age: 29,
      bio: 'Tech enthusiast and fitness lover. Enjoy trying new restaurants and travel.',
      imageUrls: ['https://i.pravatar.cc/300?img=33', 'https://i.pravatar.cc/300?img=45'],
      interests: ['Technology', 'Fitness', 'Food', 'Travel'],
      location: 'Manhattan, NY',
    );
  }

  static List<Match> getDummyMatches() {
    return [
      Match(
        id: 'match_1',
        userId: 'user_123',
        matchedUserId: 'user_2',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Match(
        id: 'match_2',
        userId: 'user_123',
        matchedUserId: 'user_5',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  static User? getUserById(String id) {
    final allUsers = [...getDummyUsers(), getCurrentUser()];
    try {
      return allUsers.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }
}
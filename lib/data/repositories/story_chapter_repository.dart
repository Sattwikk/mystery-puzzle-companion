import '../database/database_helper.dart';
import '../models/story_chapter.dart';

/// Repository for story chapters.
class StoryChapterRepository {
  StoryChapterRepository(this._db);

  final DatabaseHelper _db;

  Future<String> insertStoryChapter(StoryChapter chapter) =>
      _db.insertStoryChapter(chapter);

  Future<StoryChapter?> getStoryChapterById(String id) =>
      _db.getStoryChapterById(id);

  Future<List<StoryChapter>> getStoryChaptersByTeamId(String teamId) =>
      _db.getStoryChaptersByTeamId(teamId);
}


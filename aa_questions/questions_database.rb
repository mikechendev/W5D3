require 'singleton'
class QuestionsDatabase < SQLite3::Database
    include Singleton
    def initialize
        super('question_database.rb')
        self.type_translation = true
        self.results_as_hash = true
    end
end

class User
    attr_accessor :id, :fname, :lname
    def self.find_by_id(id)
        ids = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
            *
        FROM
            users
        WHERE id = ?
        SQL
        return nil if ids.empty?
        User.new(ids.first)
    end
    def self.find_by_name(fname, lname)
        names = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
        SELECT
            *
        FROM
            users
        WHERE fname = ?, lname = ?
        SQL
        return nil if names.empty?
        User.new(names.first)
    end
    def initialize(options)
        @id = options['id']
        @fname = options['fname']
        @lname = options['lname']
    end
end
class Question
    attr_accessor :id, :title, :body, :author_id
    def self.find_by_id(id)
        ids = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
            *
        FROM
            questions
        WHERE id = ?
        SQL
        return nil if ids.empty?
        Question.new(ids.first)
    end
end
class QuestionFollow
    attr_accessor :id, :question_id, :user_id
    # def self.find_by_id(id)
    #     question_follows = QuestionsDatabase.instance.execute(<<-SQL, id)
    #     SELECT
    #         *
    #     FROM
    #         question_follows
    #     WHERE id = ?
    #     SQL
    #     return nil if question_follows.empty?
    #     QuestionFollow.new(question_follows.first)
    # end
    def initialize(options)
        @id = options['id']
        @question_id = options['question_id']
        @user_id = options['user_id']
    end
end
class Reply
    attr_accessor :id, :question_id, :reply_id, :user_id
    def self.find_by_id(id)
        ids = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
            *
        FROM
            replies
        WHERE id = ?
        SQL
        return nil if ids.empty?
        Reply.new(ids.first)
    end
    def initialize(options)
        @id = options['id']
        @question_id = options['question_id']
        @reply_id = options['reply_id']
        @user_id = options['user_id']
    end
end
class QuestionLike
    attr_accessor :id, :user_id, :question_id
    def self.find_by_id(id)
        ids = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
            *
        FROM
            question_likes
        WHERE id = ?
        SQL
        return nil if ids.empty?
        QuestionLike.new(ids.first)
    end
    def initialize(options)
        @id = options['id']
        @user_id = options['user_id']
        @question_id = options['question_id']
    end
end
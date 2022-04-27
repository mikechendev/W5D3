require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
   include Singleton

   SQL_FILE = File.join(File.dirname(__FILE__), 'import_db.sql')
   DB_FILE = File.join(File.dirname(__FILE__), 'questions.db')

   def initialize
       super('questions.db')
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
        WHERE fname = ? AND lname = ?
        SQL
        return nil if names.empty?
        User.new(names.first)
    end
    def initialize(options)
        @id = options['id']
        @fname = options['fname']
        @lname = options['lname']
    end

    def authored_questions
        Question.find_by_author_id(@id)
    end

    def authored_replies
        Reply.find_by_user_id(@id)
    end

    def followed_questions
        QuestionFollow.followed_questions_for_user_id(@id)
    end

    def liked_questions
        QuestionLike.liked_questions_for_user_id(@id)
    end

    def average_karma
        karma = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
            COUNT(question_likes.id) / COUNT (DISTINCT(questions.id))
        FROM
            questions
        LEFT OUTER JOIN
            question_likes
        ON
            questions.id = question_likes.question_id
        WHERE
            question_likes.user_id = ?
        SQL
        karma
    end
    def save
        if !@id 
            QuestionsDatabase.instance.execute(<<-SQL, @fname, @id, @lname)
                INSERT INTO
                users (fname, id, lname)
                VALUES (?, ?, ?)
                SQL
                @id = QuestionsDatabase.instance.last_insert_row_id
        else
            QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
                UPDATE 
                users 
                SET
                fname = ?, lname = ?
                WHERE
                id = ?
                SQL
        end
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

    def self.find_by_author_id(author_id)
        ids = QuestionsDatabase.instance.execute(<<-SQL, author_id)
        SELECT
            *
        FROM
            questions
        WHERE author_id = ?
        SQL
        return nil if ids.empty?
        Question.new(ids.first)
    end
    def initialize(options)
        @id = options['id']
        @title = options['title']
        @body = options['body']
        @author_id = options['author_id']
    end
    def author
        @author_id
    end

    def replies
        Reply.find_by_question_id(@id)
    end

    def followers
        QuestionFollow.followers_for_question_id(@id)
    end
    def self.most_followed(n)
        QuestionFollow.most_followed_questions(n)
    end
    
    def likers
        QuestionLike.likers_for_question_id(@id)
    end

    def num_likes
        QuestionLike.num_likes_for_question_id(@id)
    end

    def self.most_liked(n)
       QuestionLike.most_liked_questions(n) 
    end
    def save
        if !@id 
            QuestionsDatabase.instance.execute(<<-SQL, @id, @title, @body, @author_id)
                INSERT INTO
                questions (id, title, body, author_id)
                VALUES (?, ?, ?, ?)
                SQL
                @id = QuestionsDatabase.instance.last_insert_row_id
        else
            QuestionsDatabase.instance.execute(<<-SQL,@title, @body, @author_id, @id)
                UPDATE 
                questions 
                SET
                title = ?, body = ?, author_id
                WHERE
                id = ?
                SQL
        end
    end
end

class QuestionFollow
    attr_accessor :id, :question_id, :user_id
    def self.find_by_id(id)
        question_follows = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
            *
        FROM
            question_follows
        WHERE id = ?
        SQL
        return nil if question_follows.empty?
        QuestionFollow.new(question_follows.first)
    end
    def self.followers_for_question_id(question_id)
        followers_for_question_id = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT
            users.fname, users.id, users.lname
        FROM
            question_follows
        LEFT JOIN
            users
        ON
            users.id = user_id
        WHERE question_id = ?
        SQL
        return nil if followers_for_question_id.empty?
        output =[]
        followers_for_question_id.each do |followers|
            output << User.new(followers)
        end
        output
    end
    def self.followed_questions_for_user_id(user_id)
        followed_questions_for_user_id = QuestionsDatabase.instance.execute(<<-SQL, user_id)
        SELECT
            questions.id, questions.title, questions.body, questions.author_id
        FROM
            question_follows
        LEFT JOIN
            questions
        ON
            questions.id = question_id
        WHERE user_id = ?
        SQL
        return nil if followed_questions_for_user_id.empty?
        output =[]
        followed_questions_for_user_id.each do |followed_questions|
            output << Question.new(followed_questions)
        end
        output
    end
    def self.most_followed_questions(n)
        most_followed_questions = QuestionsDatabase.instance.execute(<<-SQL, n)
        SELECT
            questions.id, questions.title, questions.body, questions.author_id
        FROM
            question_follows
        LEFT JOIN
            questions
        ON
            questions.id = question_id
        GROUP BY
            question_id
        ORDER BY
            COUNT(question_id) DESC
        LIMIT ?
        SQL
        return nil if most_followed_questions.empty?
        output =[]
        most_followed_questions.each do |questions|
            output << Question.new(questions)
        end
        output
    end
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

    def self.find_by_reply_id(reply_id)
        ids = QuestionsDatabase.instance.execute(<<-SQL, reply_id)
        SELECT
            *
        FROM
            replies
        WHERE reply_id = ?
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

    def self.find_by_user_id(user_id)
        ids = QuestionsDatabase.instance.execute(<<-SQL, user_id)
        SELECT
            *
        FROM
            replies
        WHERE user_id = ?
        SQL
        return nil if ids.empty?
        Question.new(ids.first)
    end

    def self.find_by_question_id(question_id)
        ids = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT
            *
        FROM
            replies
        WHERE question_id = ?
        SQL
        return nil if ids.empty?
        Question.new(ids.first)
    end



    def author
        @user_id
    end

    def question
        @question_id
    end

    def parent_reply
        @reply_id
    end

    def child_replies
        Reply.find_by_reply_id(@id)
    end
    def save
        if !@id 
            QuestionsDatabase.instance.execute(<<-SQL, @id, @question_id, @reply_id, @user_id)
                INSERT INTO
                replies (id, question_id, reply_id, user_id)
                VALUES (?, ?, ?, ?)
                SQL
                @id = QuestionsDatabase.instance.last_insert_row_id
        else
            QuestionsDatabase.instance.execute(<<-SQL, @question_id, @reply_id, @user_id, @id)
                UPDATE 
                replies 
                SET
                questions_id = ?, reply_id = ?, user_id = ?
                WHERE
                id = ?
                SQL
        end
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

    def self.likers_for_question_id(question_id)
        people = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT
            users.fname, users.id, users.lname
        FROM
            question_likes
        LEFT JOIN
            users
        ON
            users.id = user_id
        WHERE question_id = ?
        SQL
        return nil if people.empty?
        output =[]
        people.each do |person|
            output << User.new(person)
        end
        output
    end

    def initialize(options)
        @id = options['id']
        @user_id = options['user_id']
        @question_id = options['question_id']
    end

    def self.num_likes_for_question_id(question_id)
        people = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT
            COUNT(question_id)
        FROM
            question_likes
        LEFT JOIN
            users
        ON
            users.id = user_id
        WHERE question_id = ?
        SQL
        people.first.values.first
    end

    def self.liked_questions_for_user_id(user_id)
        questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
        SELECT
            questions.id, questions.title, questions.body, questions.author_id
        FROM
            question_likes
        LEFT JOIN
            questions
        ON
            questions.id = question_id
        WHERE user_id = ?
        SQL
        return nil if questions.empty?
        output =[]
        questions.each do |question|
            output << Question.new(question)
        end
        output
    end

    def self.most_liked_questions(n)
        most_liked_questions = QuestionsDatabase.instance.execute(<<-SQL, n)
        SELECT
            questions.id, questions.title, questions.body, questions.author_id
        FROM
            question_likes
        LEFT JOIN
            questions
        ON
            questions.id = question_id
        GROUP BY
            question_id
        ORDER BY
            COUNT(question_id) DESC
        LIMIT ?
        SQL
        return nil if most_liked_questions.empty?
        output =[]
        most_liked_questions.each do |question|
            output << Question.new(question)
        end
        output
    end

end
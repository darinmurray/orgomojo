

class CreateCoreValues < ActiveRecord::Migration[8.0]
  def up
    create_table :core_values do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    add_column :core_values, :examples, :string, array: true, default: []

    values = [
      { name: 'Integrity', description: 'Adhering to moral and ethical principles.', examples: [ 'Always tell the truth', 'Keep your promises', 'Admit mistakes honestly' ] },
          { name: 'Respect', description: 'Treating others with dignity and consideration.', examples: [ 'Listen actively', 'Avoid interrupting', 'Acknowledge others’ contributions' ] },
          { name: 'Responsibility', description: 'Being accountable for your actions.', examples: [ 'Meet deadlines', 'Own up to mistakes', 'Follow through on commitments' ] },
          { name: 'Empathy', description: 'Understanding and sharing the feelings of others.', examples: [ 'Offer support to a friend in need', 'Practice active listening', 'Avoid judgment' ] },
          { name: 'Teamwork', description: 'Working collaboratively to achieve a common goal.', examples: [ 'Share credit for success', 'Help colleagues when needed', 'Communicate openly' ] },
          { name: 'Innovation', description: 'Pursuing creative ideas and solutions.', examples: [ 'Propose new ideas', 'Experiment with different approaches', 'Embrace change' ] },
          { name: 'Excellence', description: 'Striving for the highest quality in everything you do.', examples: [ 'Pay attention to detail', 'Seek continuous improvement', 'Set high standards' ] },
          { name: 'Courage', description: 'Facing challenges and taking risks with confidence.', examples: [ 'Speak up for what is right', 'Take on difficult tasks', 'Overcome fear of failure' ] },
          { name: 'Compassion', description: 'Showing kindness and concern for others.', examples: [ 'Volunteer for a cause', 'Offer a helping hand', 'Be patient with others' ] },
          { name: 'Honesty', description: 'Being truthful and transparent.', examples: [ 'Disclose conflicts of interest', 'Provide accurate information', 'Avoid exaggeration' ] },
          { name: 'Fairness', description: 'Treating everyone equally and justly.', examples: [ 'Avoid favoritism', 'Ensure equal opportunities', 'Make impartial decisions' ] },
          { name: 'Accountability', description: 'Taking responsibility for your actions and decisions.', examples: [ 'Admit when you are wrong', 'Accept constructive criticism', 'Deliver on promises' ] },
          { name: 'Adaptability', description: 'Adjusting to new conditions and challenges.', examples: [ 'Learn new skills', 'Stay open to feedback', 'Embrace unexpected changes' ] },
          { name: 'Perseverance', description: 'Continuing to work hard despite difficulties.', examples: [ 'Complete long-term projects', 'Stay focused on goals', 'Overcome setbacks' ] },
          { name: 'Gratitude', description: 'Appreciating what you have and expressing thanks.', examples: [ 'Say thank you often', 'Keep a gratitude journal', 'Acknowledge others’ efforts' ] },
          { name: 'Humility', description: 'Being modest and respectful.', examples: [ 'Admit when you don’t know something', 'Give credit to others', 'Avoid boasting' ] },
          { name: 'Optimism', description: 'Maintaining a positive outlook.', examples: [ 'Focus on solutions', 'Encourage others', 'Look for the silver lining' ] },
          { name: 'Discipline', description: 'Maintaining self-control and focus.', examples: [ 'Stick to a schedule', 'Avoid distractions', 'Follow through on plans' ] },
          { name: 'Generosity', description: 'Willingness to give and share.', examples: [ 'Donate to charity', 'Share knowledge freely', 'Offer your time to help others' ] },
          { name: 'Patience', description: 'Remaining calm and tolerant in difficult situations.', examples: [ 'Wait your turn', 'Handle delays gracefully', 'Listen without interrupting' ] },
          { name: 'Trustworthiness', description: 'Being reliable and dependable.', examples: [ 'Keep confidences', 'Follow through on promises', 'Be consistent in actions' ] },
          { name: 'Open-mindedness', description: 'Being receptive to new ideas and perspectives.', examples: [ 'Consider alternative viewpoints', 'Avoid snap judgments', 'Be willing to change your mind' ] },
          { name: 'Self-awareness', description: 'Understanding your own emotions and behaviors.', examples: [ 'Reflect on your actions', 'Identify your strengths and weaknesses', 'Seek feedback' ] },
          { name: 'Inclusivity', description: 'Embracing diversity and ensuring everyone feels valued.', examples: [ 'Invite diverse perspectives', 'Avoid exclusionary language', 'Celebrate cultural differences' ] },
          { name: 'Kindness', description: 'Being considerate and caring towards others.', examples: [ 'Offer compliments', 'Help someone in need', 'Show appreciation' ] },
          { name: 'Loyalty', description: 'Being faithful and supportive.', examples: [ 'Stand by your friends', 'Support your team', 'Defend your principles' ] },
          { name: 'Wisdom', description: 'Applying knowledge and experience to make sound decisions.', examples: [ 'Learn from past mistakes', 'Seek advice from experts', 'Think before acting' ] },
          { name: 'Balance', description: 'Maintaining a healthy equilibrium in life.', examples: [ 'Prioritize self-care', 'Set boundaries', 'Manage time effectively' ] },
          { name: 'Forgiveness', description: 'Letting go of resentment and granting pardon.', examples: [ 'Accept apologies', 'Move on from past grievances', 'Avoid holding grudges' ] },
          { name: 'Diligence', description: 'Working hard and putting in consistent effort.', examples: [ 'Complete tasks thoroughly', 'Stay focused on goals', 'Avoid procrastination' ] },
          { name: 'Creativity', description: 'Thinking outside the box and generating new ideas.', examples: [ 'Brainstorm solutions', 'Experiment with new techniques', 'Combine different concepts' ] },
          { name: 'Determination', description: 'Resolving to achieve your goals despite obstacles.', examples: [ 'Set clear objectives', 'Stay motivated', 'Overcome challenges' ] },
          { name: 'Self-reliance', description: 'Relying on your own abilities and judgment.', examples: [ 'Solve problems independently', 'Take initiative', 'Trust your instincts' ] },
          { name: 'Focus', description: 'Concentrating on what matters most.', examples: [ 'Eliminate distractions', 'Set priorities', 'Work on one task at a time' ] },
          { name: 'Joy', description: 'Finding happiness in life’s moments.', examples: [ 'Celebrate small wins', 'Spend time with loved ones', 'Engage in hobbies' ] },
          { name: 'Curiosity', description: 'Eagerly seeking knowledge and understanding.', examples: [ 'Ask questions', 'Explore new topics', 'Read widely' ] },
          { name: 'Resilience', description: 'Bouncing back from adversity.', examples: [ 'Learn from failures', 'Stay optimistic', 'Adapt to change' ] },
          { name: 'Authenticity', description: 'Being true to yourself and your values.', examples: [ 'Express your true feelings', 'Avoid pretending to be someone else', 'Stand by your beliefs' ] },
          { name: 'Service', description: 'Contributing to the well-being of others.', examples: [ 'Volunteer in your community', 'Help a colleague', 'Support a cause you care about' ] },
          { name: 'Vision', description: 'Having a clear sense of purpose and direction.', examples: [ 'Set long-term goals', 'Inspire others with your ideas', 'Stay focused on your mission' ] }

    ]

    values.each do |value|
      ActiveRecord::Base.connection.execute(<<-SQL)
        INSERT INTO core_values (name, description, examples, created_at, updated_at)
        VALUES (
          #{ActiveRecord::Base.connection.quote(value[:name])},
          #{ActiveRecord::Base.connection.quote(value[:description])},
          '{#{value[:examples].map { |example| ActiveRecord::Base.connection.quote(example).gsub(/^'|'$/, '') }.join(',')}}',
          NOW(),
          NOW()
        );
      SQL
    end
  end

  def down
    drop_table :core_values
  end
end

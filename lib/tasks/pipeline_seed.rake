namespace :pipeline do
  desc 'Seed pipeline with sample conversations'
  task seed: :environment do
    puts '🌱 Seeding Pipeline with sample conversations...'

    account = Account.first
    unless account
      puts '❌ No account found. Please create an account first.'
      exit
    end

    inbox = account.inboxes.first
    unless inbox
      puts '❌ No inbox found. Please create an inbox first.'
      exit
    end

    # Create contacts
    contacts = []
    5.times do |i|
      contacts << Contact.find_or_create_by!(
        account: account,
        name: "Customer #{i + 1}",
        email: "customer#{i + 1}@example.com"
      )
    end

    # Create conversations in different stages
    stages = Conversation::PIPELINE_STAGES
    conversations_created = 0

    stages.each_with_index do |stage, stage_index|
      # Create 2-3 conversations per stage
      rand(2..3).times do |i|
        contact = contacts.sample
        contact_inbox = ContactInbox.find_or_create_by!(
          contact: contact,
          inbox: inbox
        )

        conversation = Conversation.create!(
          account: account,
          inbox: inbox,
          contact: contact,
          contact_inbox: contact_inbox,
          status: :open
        )

        # Set pipeline stage
        conversation.pipeline_stage = stage
        conversation.save!

        # Optionally assign to an agent
        if account.users.agents.any? && rand < 0.7
          conversation.update!(assignee: account.users.agents.sample)
        end

        conversations_created += 1
        puts "  ✅ Created conversation ##{conversation.display_id} in stage '#{stage}'"
      end
    end

    puts "\n🎉 Done! Created #{conversations_created} conversations across #{stages.count} pipeline stages."
    puts "📊 Pipeline summary:"
    stages.each do |stage|
      count = account.conversations.with_pipeline_stage(stage).count
      puts "  #{stage.capitalize}: #{count} conversations"
    end
  end

  desc 'Clear all pipeline conversations'
  task clear: :environment do
    puts '🧹 Clearing pipeline conversations...'

    Account.find_each do |account|
      count = account.conversations.in_pipeline.count
      account.conversations.in_pipeline.destroy_all
      puts "  ✅ Cleared #{count} conversations from account: #{account.name}"
    end

    puts '🎉 Done!'
  end
end

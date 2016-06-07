describe CampusSolutions::EmergencyContacts do

  let(:user_id) {'1024600'}

  shared_examples 'a proxy that gets data' do
    let(:proxy) { CampusSolutions::EmergencyContacts.new(fake: true, user_id: user_id) }
    subject { proxy.get }
    it_should_behave_like 'a simple proxy that returns errors'
    it_behaves_like 'a proxy that properly observes the emergency contact feature flag'
    it_behaves_like 'a proxy that got data successfully'
    it 'returns data with the expected structure' do

      # Guard against the empty feed when testing against real proxy with testext context
      students_feed = subject[:feed][:students]
      if students_feed
        emergency_contacts = students_feed[:student][:emergencyContacts][:emergencyContact]
        expect(emergency_contacts.length).to be

        # primary contact always at head position
        primary = emergency_contacts[0]
        expect(primary[:primaryContact]).to eq "Y"
        if primary[:emergencyPhones][:emergencyPhone].length > 0
          expect(primary[:emergencyPhones][:emergencyPhone][0][:primaryPhone]).to eq "Y"
        end

        # subsequent contacts
        i = 1
        while i < emergency_contacts.length
          contact = emergency_contacts[i]
          i += 1
          expect(contact[:primaryContact]).to eq "N"
          if contact[:emergencyPhones][:emergencyPhone].length > 0
            expect(contact[:emergencyPhones][:emergencyPhone][0][:primaryPhone]).to eq "N"
          end
        end
      end
    end
  end

  context 'mock proxy' do
    let(:fake_proxy) { true }
    it_should_behave_like 'a proxy that gets data'
  end

  context 'real proxy', testext: true do
    let(:fake_proxy) { false }
    it_should_behave_like 'a proxy that gets data'
  end
end
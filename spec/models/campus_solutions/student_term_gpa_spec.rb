describe CampusSolutions::StudentTermGpa do

  let(:user_id) { '61889' }

  shared_examples 'a proxy that gets data' do
    subject { proxy.get }
    it_should_behave_like 'a simple proxy that returns errors'
    it_behaves_like 'a proxy that properly observes the student success feature flag'
    it_behaves_like 'a proxy that got data successfully'
    it 'returns data with the expected structure' do
      expect(subject[:feed][:ucAaTermData]).to be
      expect(subject[:feed][:ucAaTermData][:ucAaTermGpa]).to be
    end
  end

  context 'mock proxy' do
    let(:proxy) { CampusSolutions::StudentTermGpa.new(user_id: user_id, fake: true) }
    it_should_behave_like 'a proxy that gets data'
  end

  context 'real proxy', testext: true do
    let(:proxy) { CampusSolutions::StudentTermGpa.new(user_id: user_id) }
    it_should_behave_like 'a proxy that gets data'
  end

end

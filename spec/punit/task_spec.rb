
#
# specifying flor
#
# Thu Jun 16 21:20:42 JST 2016
#

require 'spec_helper'


describe 'Flor punit' do

  before :each do

    @unit = Flor::Unit.new('envs/test/etc/conf.json')
    @unit.conf['unit'] = 'u'
    @unit.storage.delete_tables
    @unit.storage.migrate
    @unit.start
  end

  after :each do

    @unit.shutdown if @unit
  end

  describe 'task' do

    it 'tasks' do

      flor = %{
        task 'alpha'
      }

      r = @unit.launch(flor, wait: true)

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq('alpha')
      expect(r['payload']['seen'].size).to eq(1)
      expect(r['payload']['seen'].first[0]).to eq('alpha')
      expect(r['payload']['seen'].first[1]).to eq(nil)
      expect(r['payload']['seen'].first[2]).to eq('AlphaTasker')
    end

    it 'can be cancelled' do

      flor = %{
        sequence
          task 'hole'
      }

      r = @unit.launch(
        flor,
        payload: { 'song' => 'Marcia Baila' },
        wait: '0_0 task')
      #pp r

      expect(HoleTasker.message['exid']).to eq(r['exid'])

      r = @unit.queue(
        { 'point' => 'cancel', 'exid' => r['exid'], 'nid' => '0_0' },
        wait: true)
      #pp r

      expect(HoleTasker.message).to eq(nil)
      expect(r['point']).to eq('terminated')
      expect(r['payload'].keys).to eq(%w[ song holed ])
    end
  end
end


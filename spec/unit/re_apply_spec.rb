
#
# specifying flor
#
# Mon Feb 20 17:54:35 JST 2017
#

require 'spec_helper'


describe 'Flor unit' do

  before :each do

    @unit = Flor::Unit.new('envs/test/etc/conf.json')
    @unit.conf['unit'] = 'reapply'
    #@unit.hook('journal', Flor::Journal)
    @unit.storage.delete_tables
    @unit.storage.migrate
    @unit.start
  end

  after :each do

    @unit.shutdown
  end

  describe 're-applying a node' do

    it 'works (node with children)' do

      flor = %{
        sequence
          sequence
            stall _
      }

      r = @unit.launch(flor, wait: '0_0_0 receive; end')
      exid = r['exid']

      #sleep 0.350

      new_tree = %{
        sequence
          alpha _
      }

      @unit.re_apply(
        exid: exid, nid: '0_0',
        tree: new_tree,
        payload: { 'text' => 'hello world' })

      r = @unit.wait(exid, 'terminated')

      expect(r['payload']['seen'].size).to eq(1)
      expect(r['payload']['seen'][0][0]).to eq('alpha')
      expect(r['payload']['text']).to eq('hello world')
    end

    it 'works (leaf node)' do

      flor = %{
        sequence
          stall _
      }

      r = @unit.launch(flor, wait: '0_0 receive; end')
      exid = r['exid']

      #sleep 0.350

      new_tree = %{ alpha _ }

      @unit.re_apply(
        exid: exid, nid: '0_0',
        tree: new_tree,
        payload: { 'text' => 'hello world' })

      r = @unit.wait(exid, 'terminated')

      expect(r['payload']['seen'].size).to eq(1)
      expect(r['payload']['seen'][0][0]).to eq('alpha')
      expect(r['payload']['text']).to eq('hello world')
    end

    it 'works (tasker leaf node)' do

      flor = %{
        sequence
          hole _
      }

      r = @unit.launch(flor, wait: '0_0 task; end')
      exid = r['exid']

      #sleep 0.350

      new_tree = %{ alpha _ }

      @unit.re_apply(
        exid: exid, nid: '0_0',
        tree: new_tree,
        payload: { 'text' => 'hello world' })

      r = @unit.wait(exid, 'terminated')

      expect(r['payload']['seen'].size).to eq(1)
      expect(r['payload']['seen'][0][0]).to eq('alpha')
      expect(r['payload']['text']).to eq('hello world')
    end

    it 'works (subnid node)' do

      flor = %{
        set a 0
        loop
          set a (+ a 1)
          continue _ if a < 2
          stall _
      }

      r = @unit.launch(flor, wait: 'end')
      exid = r['exid']

      #sleep 0.350

      new_tree = %{ alpha _ }

      @unit.re_apply(
        exid: exid, nid: '0_1_2-1',
        tree: new_tree,
        payload: { 'text' => 'hello world -1' })

      r = @unit.wait(exid, '0_1_2-2 receive')

      expect(r['payload']['seen'].size).to eq(1)
      expect(r['payload']['seen'][0][0]).to eq('alpha')
      expect(r['payload']['text']).to eq('hello world -1')
    end
  end
end


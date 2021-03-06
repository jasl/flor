
#
# specifying flor
#
# Thu Mar 31 16:17:39 JST 2016
#

require 'spec_helper'


describe 'Flor core' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'a variable as head' do

    it 'is derefenced upon application' do

      flor = %{
        set a
          sequence
        #$(f.a)
        a
          1
          2
      }

      r = @executor.launch(flor)

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq(2)
    end
  end

  describe 'a variable reference' do

    it 'yields the value' do

      flor = %{
        [ key, v.key ]
      }

      r = @executor.launch(flor, vars: { 'key' => 'a major' })

      expect(r['point']).to eq('terminated')
      expect(r['vars']['key']).to eq('a major')
      expect(r['payload']['ret']).to eq([ 'a major' ] * 2)
    end

    it 'fails else' do

      flor = %{
        key
      }

      r = @executor.launch(flor)

      expect(r['point']).to eq('failed')
      expect(r['error']['msg']).to eq("don't know how to apply \"key\"")
    end

      # not super sure about this one
      # regular interpreters fail on this one
      # limiting this behaviour to fields is better, probably
      #
    it 'yields null if referenced with a v. prefix'# do
#
#      flor = %{
#        v.a
#      }
#
#      r = @executor.launch(flor)
#
#      expect(r['point']).to eq('terminated')
#      expect(r['payload']['ret']).to eq(nil)
#    end
  end

  describe 'a variable deep reference' do

    it 'yields the desired value' do

      flor = %{
        set c a.0
        a.0.b
      }

      r = @executor.launch(flor, vars: { 'a' => [ { 'b' => 'c' } ] })

      expect(r['point']).to eq('terminated')
      expect(r['vars']['c']).to eq({ 'b' => 'c' })
      expect(r['payload']['ret']).to eq('c')
    end

    it 'yields null when the container exists'# do
#
#      flor = %{
#        [ a.0, h.k0 ]
#      }
#
#      r = @executor.launch(flor, vars: { 'a' => [], 'h' => {} })
#
#      expect(r['point']).to eq('terminated')
#      expect(r['payload']['ret']).to eq([ nil, nil ])
#    end
  end

  describe 'the "node" pseudo-variable' do

    it 'gives access to the node' do

      flor = %{
        push f.l node.nid
        push f.l "$(node.nid)"
        push f.l node.heat0
        push f.l "$(node.heat0)"
      }

      r = @executor.launch(flor, payload: { 'l' => [] })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['l']).to eq(%w[ 0_0_1 0_1_1 node.heat0 _dqs ])
    end
  end
end


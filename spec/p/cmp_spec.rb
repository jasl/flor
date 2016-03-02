
#
# specifying flor
#
# Wed Mar  2 20:44:53 JST 2016
#

require 'spec_helper'


describe 'Flor procedures' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe '=' do

    it 'compares strings' do

      rad = %{
        sequence
          push f.l
            =
              val "alpha"
              val alpha
          push f.l
            =
              val "alpha"
              val "bravo"
      }

      r = @executor.launch(rad, payload: { 'l' => [] })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq(false)
      expect(r['payload']['l']).to eq([ true, false ])
    end

    it 'compares integers' do

      rad = %{
        sequence
          push f.l
            =
              1
              1
          push f.l
            =
              1
              -1
      }

      r = @executor.launch(rad, payload: { 'l' => [] })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq(false)
      expect(r['payload']['l']).to eq([ true, false ])
    end

    it 'compares booleans' do

      rad = %{
        sequence
          push f.l
            =
              true
              true
          push f.l
            =
              false
              false
          push f.l
            =
              true
              false
      }

      r = @executor.launch(rad, payload: { 'l' => [] })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq(false)
      expect(r['payload']['l']).to eq([ true, true, false ])
    end

    it 'compares nulls' do

      rad = %{
        sequence
          push f.l
            =
              null
              null
          push f.l
            =
              null
              false
      }

      r = @executor.launch(rad, payload: { 'l' => [] })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq(false)
      expect(r['payload']['l']).to eq([ true, false ])
    end

    it 'compares arrays' do

      rad = %{
        sequence
          push f.l
            =
              [ 1, 2 ]
              [ 1, 2 ]
          push f.l
            =
              [ 1, 2 ]
              [ 1, 2 ]
              [ 'a' ]
      }

      r = @executor.launch(rad, payload: { 'l' => [] })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq(false)
      expect(r['payload']['l']).to eq([ true, false ])
    end

    it 'compares objects' do

      rad = %{
        sequence
          push f.l
            =
              { a: 1, b: 2 }
              { a: 1, b: 2 }
          push f.l
            =
              { a: 1, b: 2 }
              { a: 1, b: 2, c: 3 }
      }

      r = @executor.launch(rad, payload: { 'l' => [] })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq(false)
      expect(r['payload']['l']).to eq([ true, false ])
    end
  end
end

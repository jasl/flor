
#
# specifying flor
#
# Sat Jun 18 16:43:30 JST 2016
#

require 'spec_helper'


describe Flor::Loader do

  before :each do

    unit = OpenStruct.new(conf: { 'lod_path' => 'envs/uspec_loader' })
      # force a specific file hieararchy root on the loader via 'lod_path'

    @loader = Flor::Loader.new(unit)
  end

  describe '#variables' do

    it 'loads variables' do

      n = @loader.variables('net')

      expect(n['car']).to eq('fiat')

      ne = @loader.variables('net.example')

      expect(ne['car']).to eq('alfa romeo')
      expect(ne['flower']).to eq('rose')

      oe = @loader.variables('org.example')

      expect(oe['car']).to eq(nil)
      expect(oe['flower']).to eq('lilly')

      nea = @loader.variables('net.example.alpha')

      expect(nea['car']).to eq('lancia')
      expect(nea['flower']).to eq('forget-me-not')
    end
  end

  describe '#library' do

    it 'loads a lib' do

      pa, fn = @loader.library('net.example', 'flow1')

      expect(
        pa
      ).to eq(
        'envs/uspec_loader/usr/net.example/lib/flows/flow1.flo'
      )

      expect(
        fn.strip
      ).to eq(%{
        task 'alice'
      }.strip)

      pa, fn = @loader.library('org.example.flow1')

      expect(
        fn.strip
      ).to eq(%{
        task 'oskar'
      }.strip)
    end
  end

  describe '#tasker' do

    it 'loads a tasker configuration' do

      t = @loader.tasker('', 'alice')

      expect(t['description']).to eq('basic alice')
      expect(t.keys).to eq(%w[ description a _path root ])

      t = @loader.tasker('net.example', 'alice')

      expect(t['description']).to eq('basic alice')
      expect(t.keys).to eq(%w[ description a _path root ])

      t = @loader.tasker('org.example', 'alice')

      expect(t['description']).to eq('org.example alice')
      expect(t.keys).to eq(%w[ description ao _path root ])

      t = @loader.tasker('', 'bob')

      expect(t).to eq(nil)

      t = @loader.tasker('net.example', 'bob')

      expect(t['description']).to eq('usr net.example bob')
      expect(t.keys).to eq(%w[ description ubn _path root ])

      t = @loader.tasker('org.example', 'bob')

      expect(t['description']).to eq('org.example bob')
      expect(t.keys).to eq(%w[ description bo _path root ])

      t = @loader.tasker('org.example.bob')

      expect(t['description']).to eq('org.example bob')
      expect(t.keys).to eq(%w[ description bo _path root ])
    end

    it 'loads a domain tasker configuration' do

      tc = @loader.tasker('com.example.tasker')
      expect(tc['description']).to eq('/cet/dot.json')

      tc = @loader.tasker('com.example', 'tasker')
      expect(tc['description']).to eq('/cet/dot.json')

      tc = @loader.tasker('com.example.alpha.tasker')
      expect(tc['description']).to eq('/usr/ceat/dot.json')

      tc = @loader.tasker('com.example.alpha', 'tasker')
      expect(tc['description']).to eq('/usr/ceat/dot.json')

      tc = @loader.tasker('com.example.bravo.tasker')
      expect(tc['description']).to eq('/usr/cebt/flor.json')

      tc = @loader.tasker('com.example.bravo', 'tasker')
      expect(tc['description']).to eq('/usr/cebt/flor.json')

      tc = @loader.tasker('com.example.charly', 'tasker')
      expect(tc['description']).to eq('/cect.json')
    end

    it 'loads a tasker configuration {name}.json' do

      tc = @loader.tasker('org.example', 'charly')
      expect(tc['description']).to eq('org.example charly')

      expect(File.basename(tc['_path'])).to eq('charly.json')
    end

    it 'loads a tasker configuration do.ma.in.json' do

      tc = @loader.tasker('mil.example', 'staff')
      expect(tc['description']).to eq('mil.example.staff')

      tc = @loader.tasker('mil.example.ground', 'staff')
      expect(tc['description']).to eq('mil.example.ground.staff')

      tc = @loader.tasker('mil.example.air', 'command')
      expect(tc['description']).to eq('mil.example.air.command')

      tc = @loader.tasker('mil.example.air.tactical', 'command')
      expect(tc['description']).to eq('mil.example.air.command')

      expect(File.basename(tc['_path'])).to eq('air.json')
    end

    it 'loads a tasker array configuration do.ma.in.json' do

      tc = @loader.tasker('mil.example.air.tactical', 'intel')

      expect(tc.size).to eq(2)

      expect(tc[0]['point']).to eq('task')
      expect(tc[1]['point']).to eq('detask')

      expect(tc[0]['_path']).to match(
        /\/envs\/uspec_loader\/usr\/mil\.example\/lib\/taskers\/air\.json\z/)
      expect(tc[1]['_path']).to match(
        /\/envs\/uspec_loader\/usr\/mil\.example\/lib\/taskers\/air\.json\z/)
    end
  end

  describe '#hooks' do

    it 'returns the sum of the hooks for a domain' do

      hooks = @loader.hooks('org.example')

      expect(hooks).to eq([
        { 'point' => 'execute',
          'require' => 'xyz/my_hooks.rb', 'class' => 'Xyz::MyExecuteHook',
          '_path' => $flor_path + 'envs/uspec_loader/lib/hooks/dot.json:0' },
        { 'point' => 'terminated',
          'require' => 'xyz/my_hooks.rb', 'class' => 'Xyz::MyGenericHook',
          '_path' => $flor_path + 'envs/uspec_loader/lib/hooks/dot.json:1' },
        { 'point' => 'execute',
          'require' => 'xyz/oe_hooks.rb', 'class' => 'Xyz::OeExecuteHook',
          '_path' => $flor_path + 'envs/uspec_loader/lib/hooks/org.example.json:0' }
      ])
    end

    it 'loads from hooks.json' do

      hooks = @loader.hooks('mil.example')

      expect(hooks).to eq([
        { 'point' => 'execute',
          'require' => 'xyz/my_hooks.rb', 'class' => 'Xyz::MyExecuteHook',
          '_path' => $flor_path + 'envs/uspec_loader/lib/hooks/dot.json:0' },
        { 'point' => 'terminated',
          'require' => 'xyz/my_hooks.rb', 'class' => 'Xyz::MyGenericHook',
          '_path' => $flor_path + 'envs/uspec_loader/lib/hooks/dot.json:1' },
        { 'point' => 'receive',
          'require' => 'xyz/me_hooks.rb', 'class' => 'Xyz::MeReceiveHook',
          '_path' => $flor_path + 'envs/uspec_loader/usr/mil.example/lib/hooks/hooks.json:0' }
      ])
    end
  end
end


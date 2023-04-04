RSpec.shared_context('async execution', shared_context: :metadata) do |job_class:, shutdown_timeout: 5|
  def test_adapters
    @test_adapters ||= {}
  end

  def gj_adapters
    @gj_adapters ||= {}
  end

  def latches
    @latches ||= {}
  end

  def callback_procs
    @callback_procs ||= {}
  end

  def await_performed(job_class, timeout: 3)
    latch = latches[job_class]
    latch.wait(timeout)
    expect(latch.count).to eq(0), "#{job_class} not performed within #{timeout}s timeout"
  end

  before do
    test_adapters[job_class] = job_class.queue_adapter
    job_class.disable_test_adapter

    latches[job_class] = Concurrent::CountDownLatch.new.tap do |latch|
      callback_proc = -> do
        latch.count_down
      end
      job_class.after_perform(&callback_proc)
      callback_procs[job_class] = callback_proc
    end

    job_class.queue_adapter = :good_job
    job_class.queue_adapter.tap do |gj|
      gj.instance_variable_set(:@_in_server_process, true)
      gj.start_async
      gj_adapters[job_class] = gj
    end
  end

  after do
    gj_adapter = gj_adapters[job_class]
    gj_adapter.shutdown(timeout: shutdown_timeout)

    callback_proc = callback_procs[job_class]
    callback_chain = job_class.__callbacks[:perform].instance_variable_get(:@chain)
    callback = callback_chain.find { |cb| cb.instance_variable_get(:@filter) == callback_proc }
    callback_chain.delete(callback)

    test_adapter = test_adapters[job_class]
    job_class.enable_test_adapter(test_adapter)
  end
end

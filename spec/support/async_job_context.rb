RSpec.shared_context('async execution', shared_context: :metadata) do |job_class:, shutdown_timeout: 5, rescue_exception: true|
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

  def rescue_procs
    @rescue_procs ||= {}
  end

  def await_performed(job_class, timeout: 3)
    latch = latches[job_class]
    latch.wait(timeout)
    expect(latch.count).to eq(0), "#{job_class} not performed within #{timeout}s timeout"
  end

  def add_rescue_handler(job_class, from:, &block)
    job_class.rescue_from(from, &block)

    rps_for_jc = (rescue_procs[job_class] ||= [])
    rps_for_jc << block
  end

  before do
    test_adapters[job_class] = job_class.queue_adapter
    job_class.disable_test_adapter

    if rescue_exception
      add_rescue_handler(job_class, from: Exception) do |ex|
        raise StandardError, ex.message
      end
    end

    latches[job_class] = Concurrent::CountDownLatch.new.tap do |latch|
      # NOTE: We need to use around_perform since after_perform isn't called in the event of an error
      callback_proc = ->(_job, block) do
        begin
          block.call
        ensure
          latch.count_down
        end
      end
      job_class.around_perform(&callback_proc)
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

    if (rps_for_jc = rescue_procs[job_class])
      handlers = job_class.rescue_handlers

      rps_for_jc.each do |rescue_proc|
        handlers.reject! { |(_k, p)| p == rescue_proc }
      end
    end

    test_adapter = test_adapters[job_class]
    job_class.enable_test_adapter(test_adapter)
  end
end

RSpec.shared_context('async execution', shared_context: :metadata) do |job_class:, rescue_exception: true|
  def gj_adapter
    @gj_adapter ||= GoodJob::Adapter.new execution_mode: :async_all
  end

  def old_adapters
    @old_adapters ||= {}
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

    old_adapters[job_class] = job_class.queue_adapter
    # This is needed for the scheduled jobs in the LocationRequestsController spec.
    # We don't re-enable later, because we've already saved the previous queue adapter.
    # The 'test_adapter' overrides the queue adapter, but since we're putting it back
    # as the queue adapter anyway, behaviour should remain functionally equivalent to
    # re-enabling the test adapter as the test adapter.
    job_class.disable_test_adapter
    job_class.queue_adapter = gj_adapter
  end

  after do
    job_class.skip_callback :perform, :around, callback_procs[job_class]

    if (rps_for_jc = rescue_procs[job_class])
      handlers = job_class.rescue_handlers

      rps_for_jc.each do |rescue_proc|
        handlers.reject! { |(_k, p)| p == rescue_proc }
      end
    end

    job_class.queue_adapter = old_adapters.delete(job_class)
  end
end

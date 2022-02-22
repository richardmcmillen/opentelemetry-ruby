# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::MeterProvider do
  before do
    reset_metrics_sdk
    OpenTelemetry::SDK.configure
  end

  describe '#meter' do
    it 'requires a meter name' do
      _(-> { OpenTelemetry.meter_provider.meter }).must_raise(ArgumentError)
    end

    it 'creates a new meter' do
      meter = OpenTelemetry.meter_provider.meter('test')

      _(meter).must_be_instance_of(OpenTelemetry::SDK::Metrics::Meter)
    end

    it 'repeated calls does not recreate a meter of the same name' do
      meter_a = OpenTelemetry.meter_provider.meter('test')
      meter_b = OpenTelemetry.meter_provider.meter('test')

      _(meter_a).must_equal(meter_b)
    end
  end

  describe '#shutdown' do
    it 'repeated calls to shutdown result in a failure' do
      with_test_logger do |log_stream|
        _(OpenTelemetry.meter_provider.shutdown).must_equal(OpenTelemetry::SDK::Metrics::Export::SUCCESS)
        _(OpenTelemetry.meter_provider.shutdown).must_equal(OpenTelemetry::SDK::Metrics::Export::FAILURE)
        _(log_stream.string).must_match(/calling MetricProvider#shutdown multiple times/)
      end
    end

    it 'returns a no-op meter after being shutdown' do
      with_test_logger do |log_stream|
        OpenTelemetry.meter_provider.shutdown

        _(OpenTelemetry.meter_provider.meter('test')).must_be_instance_of(OpenTelemetry::Metrics::Meter)
        _(log_stream.string).must_match(/calling MeterProvider#meter after shutdown, a noop meter will be returned/)
      end
    end

    it 'returns a timeout response when it times out' do
      mock_metric_reader = Minitest::Mock.new
      mock_metric_reader.expect(:nothing_gets_called_because_it_times_out_first, nil)
      OpenTelemetry.meter_provider.add_metric_reader(mock_metric_reader)

      _(OpenTelemetry.meter_provider.shutdown(timeout: 0)).must_equal(OpenTelemetry::SDK::Metrics::Export::TIMEOUT)
    end

    it 'invokes shutdown on all registered Metric Readers' do
      mock_metric_reader_1 = Minitest::Mock.new
      mock_metric_reader_2 = Minitest::Mock.new
      mock_metric_reader_1.expect(:shutdown, nil, [{ timeout: nil }])
      mock_metric_reader_2.expect(:shutdown, nil, [{ timeout: nil }])

      OpenTelemetry.meter_provider.add_metric_reader(mock_metric_reader_1)
      OpenTelemetry.meter_provider.add_metric_reader(mock_metric_reader_2)
      OpenTelemetry.meter_provider.shutdown

      mock_metric_reader_1.verify
      mock_metric_reader_2.verify
    end
  end

  describe '#force_flush' do
    it 'returns a timeout response when it times out' do
      mock_metric_reader = Minitest::Mock.new
      mock_metric_reader.expect(:nothing_gets_called_because_it_times_out_first, nil)
      OpenTelemetry.meter_provider.add_metric_reader(mock_metric_reader)

      _(OpenTelemetry.meter_provider.force_flush(timeout: 0)).must_equal(OpenTelemetry::SDK::Metrics::Export::TIMEOUT)
    end

    it 'invokes force_flush on all registered Metric Readers' do
      mock_metric_reader_1 = Minitest::Mock.new
      mock_metric_reader_2 = Minitest::Mock.new
      mock_metric_reader_1.expect(:force_flush, nil, [{ timeout: nil }])
      mock_metric_reader_2.expect(:force_flush, nil, [{ timeout: nil }])
      OpenTelemetry.meter_provider.add_metric_reader(mock_metric_reader_1)
      OpenTelemetry.meter_provider.add_metric_reader(mock_metric_reader_2)

      OpenTelemetry.meter_provider.force_flush

      mock_metric_reader_1.verify
      mock_metric_reader_2.verify
    end
  end

  describe '#add_metric_reader' do
    it 'adds a metric reader' do
      metric_reader = OpenTelemetry::SDK::Metrics::Export::MetricReader.new(
        OpenTelemetry::SDK::Metrics::Export::ConsoleExporter.new
      )

      OpenTelemetry.meter_provider.add_metric_reader(metric_reader)

      _(OpenTelemetry.meter_provider.instance_variable_get(:@metric_readers)).must_equal([metric_reader])
    end
  end

  describe '#add_view' do
    # TODO
  end
end

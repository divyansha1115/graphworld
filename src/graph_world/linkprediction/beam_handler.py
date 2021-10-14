import logging

import apache_beam as beam
import gin
import numpy as np
import pandas as pd
from torch_geometric.data import DataLoader

from ..beam.generator_beam_handler import GeneratorBeamHandler
from ..beam.generator_config_sampler import GeneratorConfigSampler, ParamSamplerSpec
from ..models.benchmarker import Benchmarker, BenchmarkGNNParDo
from ..sbm.beam_handler import SampleSbmDoFn, WriteSbmDoFn, ComputeSbmGraphMetrics
from ..sbm.utils import sbm_data_to_torchgeo_data, get_kclass_masks
from .utils import sample_data


class ConvertToTorchGeoDataParDo(beam.DoFn):
  def __init__(self, training_ratio):
    self._training_ratio = training_ratio

  def process(self, element):
    sample_id = element['sample_id']
    sbm_data = element['data']

    out = {
        'sample_id': sample_id,
        'metrics': element['metrics'],
        'torch_data': None,
        'masks': None,
        'skipped': False
    }

    try:
      torch_data = sbm_data_to_torchgeo_data(sbm_data)
      torch_data = sample_data(torch_data, self._training_ratio)
      out['torch_data'] = torch_data
      out['generator_config'] = element['generator_config']
    except:
      out['skipped'] = True
      print(f'failed to convert {sample_id}')
      logging.info(f'Failed to convert sbm_data to torchgeo for sample id {sample_id}')
      yield out
      return

    yield out


@gin.configurable
class LinkPredictionBeamHandler(GeneratorBeamHandler):

  @gin.configurable
  def __init__(self, param_sampler_specs, benchmarker_wrappers, training_ratio):
    self._sample_do_fn = SampleSbmDoFn(param_sampler_specs)
    self._benchmark_par_do = BenchmarkGNNParDo(benchmarker_wrappers)
    self._metrics_par_do = ComputeSbmGraphMetrics()
    self._training_ratio = training_ratio

  def GetSampleDoFn(self):
    return self._sample_do_fn

  def GetWriteDoFn(self):
    return self._write_do_fn

  def GetConvertParDo(self):
    return self._convert_par_do

  def GetBenchmarkParDo(self):
    return self._benchmark_par_do

  def GetGraphMetricsParDo(self):
    return self._metrics_par_do

  def SetOutputPath(self, output_path):
    self._output_path = output_path
    self._write_do_fn = WriteSbmDoFn(output_path)
    self._convert_par_do = ConvertToTorchGeoDataParDo(self._training_ratio)
    self._benchmark_par_do.SetOutputPath(output_path)
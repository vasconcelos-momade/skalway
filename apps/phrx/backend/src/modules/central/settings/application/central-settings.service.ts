import { CentralSettingsRepository } from "../infrastructure/central-settings.repository";
import { GetCentralSettingsUseCase } from "../application/use-cases/get-central-settings.use-case";
import { UpdateCentralSettingsUseCase } from "../application/use-cases/update-central-settings.use-case";
import type {
  CentralSettingsDTO,
  UpdateCentralSettingsInput,
} from "../domain/central-settings.types";

/**
 * Fachada de aplicação para CentralSettings (singleton institucional).
 */
export class CentralSettingsService {
  private readonly repository = new CentralSettingsRepository();
  private readonly getUseCase = new GetCentralSettingsUseCase(this.repository);
  private readonly updateUseCase = new UpdateCentralSettingsUseCase(
    this.repository,
  );

  get(): Promise<CentralSettingsDTO> {
    return this.getUseCase.execute();
  }

  update(input: UpdateCentralSettingsInput): Promise<CentralSettingsDTO> {
    return this.updateUseCase.execute(input);
  }
}
